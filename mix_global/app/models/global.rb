# TODO config.active_record.cache_versioning
# TODO for tests, use MemoryStore and compare outputs and keys
class Global < LibRecord
  include GlobalCache

  attribute :data

  enum data_type: {
    string:      0,
    json:       10,
    boolean:    20,
    integer:    30,
    decimal:    40,
    datetime:   50,
    interval:   60,
    serialized: 70,
  }

  scope :expired, -> {
    updated_at, expires_at = column(:updated_at), column(:expires_at)
    expirable.where((updated_at < past_expires_at).or((expires_at != nil).and expires_at < Time.current))
  }
  scope :ongoing, -> {
    updated_at, expires_at = column(:updated_at), column(:expires_at)
    expirable.where((updated_at > past_expires_at).and((expires_at == nil).or expires_at > Time.current))
  }
  scope :expirable, -> { where(expires: true) }
  scope :permanent, -> { where(expires: false) }

  validates :id, length: { maximum: 2712 }
  validates :expires_at, date: { after: proc{ 1.second.from_now }, before: proc{ future_expires_at }, allow_blank: true }

  after_initialize :set_data

  def self.past_expires_at(from: ::Time.current)
    expires_in.seconds.ago(from)
  end

  def self.future_expires_at(from: ::Time.current)
    expires_in.seconds.since(from)
  end

  def self.past_touch_at(from: ::Time.current)
    touch_in.seconds.ago(from)
  end

  def self.future_touch_at(from: ::Time.current)
    touch_in.seconds.since(from)
  end

  def self.expires_in
    MixGlobal.config.expires_in
  end

  def self.touch_in
    MixGlobal.config.touch_in
  end

  # TODO select('COALESCE(...)' AS data)
  def self.fetch_record(name, **options)
    options = options.reverse_merge expires: true
    if block_given?
      if options.delete(:force)
        write(name, yield, **options)
      else
        key = normalize_key(name)
        version = normalize_version(name, **options)
        record = find_or_create_by! id: key do |record|
          record.assign_attributes options.slice(:expires, :expires_in).merge!(id: key, version: version, data: yield)
        end
        if record._sync(version, &proc).destroyed?
          fetch_record(key, version: version, **options, &proc)
        end
        record
      end
    elsif options[:force]
      raise ArgumentError, "Missing block: Calling `Global#fetch_record` with `force: true` requires a block."
    else
      read_record(name, **options)
    end
  end

  ### Useful statements for the block:
  # - new record --> record.nil?
  # - skip write --> throw :skip_write
  # - rollback   --> throw :abort
  def self.write_record(name, value = nil, **options)
    options = options.reverse_merge expires: true
    block = block_given? ? proc : proc{ value }
    record = fetch_record(name, **options, &block)
    unless record.new?
      record.with_lock do
        version = normalize_version(name, **options)
        catch(:skip_write) do
          record.update! options.slice(:expires, :expires_in).merge!(version: version, data: block.call(record))
        end
      end
    end
    record
  rescue ActiveRecord::RecordNotFound
    # TODO test it (must not be inside a transaction block?)
    # https://dev.to/evilmartians/the-silence-of-the-ruby-exceptions-a-railspostgresql-database-transaction-thriller-5e30
    retry
  end

  def self.read_record(name, **options)
    key = normalize_key(name)
    if (record = find_by(id: key))
      version = normalize_version(name, **options)
      record unless record._sync_stale_state(version).stale?
    end
  end

  def self.read_records(names, **options)
    case names
    when Array
      keys = names.map{ |element| normalize_key(element) }
      where(id: keys).find_each.with_object({}).each do |record, memo|
        key = record.id
        version = normalize_version(names[keys.index(key)], **options)
        memo[key] = record unless record._sync_stale_state(version).stale?
      end
    when Regexp
      version = normalize_version(**options)
      where(column(:id).matches key_matcher(names, **options)).find_each.with_object({}).each do |record, memo|
        memo[record.id] = record unless record._sync_stale_state(version).stale?
      end
    else
      raise ArgumentError, "Bad type: `Global#read_records` requires names as Array or Regexp."
    end
  end

  def self.delete_record(name)
    key = normalize_key(name)
    where(id: key).delete_all
  end

  def self.delete_records(matcher, **options)
    case matcher
    when Array  then matcher = GlobalKey.start_with(matcher)
    when Regexp then # do nothing
    else raise ArgumentError, "Bad type: `Global#delete_records` requires matcher as Array or Regexp."
    end
    where(column(:id).matches key_matcher(matcher, **options)).delete_all
  end

  def self.update_integer(name, amount, **options)
    raise ArgumentError, "Bad type: `Global#update_integer` requires amount as Integer." unless amount.is_a? Integer

    options = options.reverse_merge expires: true
    key = normalize_key(name)
    if (result = update_counter(key, amount)).nil?
      version = normalize_version(name, **options)
      create! options.slice(:expires, :expires_in).merge!(id: key, version: version, data: amount)
      result = amount
    end
    result
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.update_counter(key, amount)
    raise ArgumentError, "Bad value: `Global#update_counter` requires amount != 0." if amount == 0

    operator = amount < 0 ? "-" : "+"
    quoted_column = connection.quote_column_name(:integer)
    updates = ["#{quoted_column} = COALESCE(#{quoted_column}, 0) #{operator} #{amount.abs}"]

    touch_updates = touch_attributes_with_time
    updates << sanitize_sql_for_assignment(touch_updates)

    unscoped.where(id: key).update_all(updates.join(", "), quoted_column)
  end

  def self.normalize_key(key, **)
    # no namespace functionality implemented on purpose --> https://github.com/kickstarter/rack-attack/issues/370
    expanded_key(key).full_underscore(GlobalKey::SEPARATOR)
  end

  def self.expanded_key(key)
    return key.cache_key.to_s if key.respond_to? :cache_key

    case key
    when Array
      key = (key.size > 1) ? key.map{ |element| expanded_key(element) } : key.first
    when Hash
      key = key.sort_by{ |k, _| k.to_s }.map{ |k, v| "#{k}=#{v}" }
    end

    key.to_param
  end

  def self.normalize_version(key = nil, version: nil, **)
    (version&.to_param || expanded_version(key || '')).presence
  end

  def self.expanded_version(key)
    case
    when key.respond_to?(:cache_version) then key.cache_version.to_param
    when key.is_a?(Array)                then key.map{ |element| expanded_version(element) }.compact.to_param
    when key.respond_to?(:to_a)          then expanded_version(key.to_a)
    end
  end

  def self.key_matcher(pattern, **)
    regex = pattern.source.tr('/', GlobalKey::SEPARATOR)
    if !regex.start_with?('^') || regex.in?(['', '^', '$']) || regex.exclude?(GlobalKey::SEPARATOR)
      raise ArgumentError, "Bad value: `Global#key_matcher` pattern /#{regex}/ matches too much."
    end
    sanitize_matcher /#{regex}/
  end

  def expirable?
    expires
  end

  def permanent?
    !expirable?
  end

  def expired?
    expirable? && (self.class.future_expires_at(from: updated_at).past? || expires_at&.past?)
  end

  def expired_touch?
    expirable? && self.class.future_touch_at(from: updated_at).past?
  end

  def ongoing?
    expirable? && self.class.future_expires_at(from: updated_at).future? && (expires_at.nil? || expires_at.future?)
  end

  def expires_in
    if expires_at
      (expires_at - Time.current).to_i
    elsif expires
      (self.class.future_expires_at(from: updated_at) - Time.current).to_i
    end
  end

  # TODO doesn't seems to work well (Rack::Attack) --> unit tests
  def expires_in=(value)
    if value && !@freeze_expires
      self.expires = true
      self.expires_at = value.seconds.from_now
    end
    value
  end

  def expires=(value)
    @freeze_expires = !value
    self.expires_at = nil unless value
    self[:expires] = value
  end

  def data=(data)
    if (new_type = type_of(data)) != data_type
      self[data_type] = nil
      self.data_type = new_type
    end
    if new_type == 'serialized'
      self[data_type] = Marshal.dump(data)
      self[:data] = data
    else
      self[:data] = self[data_type] = cast(data)
    end
  end

  def stale?
    destroyed? || changed?
  end

  def _sync(version)
    return self if new?

    _sync_stale_state(version)

    return self if destroyed?

    if changed?
      with_lock do
        update! data: yield
      rescue ActiveRecord::RecordNotFound
        destroyed!
      end
    end

    self
  end

  def _sync_stale_state(version)
    if expired?
      delete
    elsif expired_touch?
      destroyed! unless touch
    else
      self.version = version
    end

    self
  end

  private

  def type_of(data)
    case data
    when Array, Hash             then 'json'
    when Boolean                 then 'boolean'
    when Integer                 then 'integer'
    when Float, BigDecimal       then 'decimal'
    when Date, Time, DateTime    then 'datetime'
    when ActiveSupport::Duration then 'interval'
    when String, Symbol, nil     then 'string'
    else                              'serialized'
    end
  end

  def set_data
    self[:data] = cast(self[data_type])
    clear_attribute_changes [:data]
  end

  def cast(data)
    return data unless data

    if data_type == 'serialized'
      Marshal.load(data) rescue data
    else
      data
    end
  end
end
