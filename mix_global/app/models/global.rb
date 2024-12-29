# frozen_string_literal: true

class Global < MixGlobal.config.parent_model.to_const!
  include GlobalCache

  belongs_to :server, -> { with_discarded }

  attribute :data

  enum :data_type, {
    string:      0,
    json:       10,
    boolean:    20,
    integer:    30,
    decimal:    40,
    datetime:   50,
    interval:   60,
    symbol:     80,
  }

  scope :expired, -> {
    updated_at, expires_at = column(:updated_at), column(:expires_at)
    expirable.where((updated_at < past_expires_at).or((expires_at.not_eq nil).and expires_at < Time.current))
  }
  scope :ongoing, -> {
    updated_at, expires_at = column(:updated_at), column(:expires_at)
    expirable.where((updated_at > past_expires_at).and((expires_at.eq nil).or expires_at > Time.current))
  }
  scope :expirable, -> { where(expires: true) }
  scope :permanent, -> { where(expires: false) }

  validates :id, length: { maximum: 2712 }
  validates :expires_at, date: { after: proc{ 1.second.from_now }, before: proc{ future_expires_at }, allow_blank: true }

  after_initialize :set_defaults

  def self.past_expires_at(from: Time.current)
    expires_in.seconds.ago(from)
  end

  def self.future_expires_at(from: Time.current)
    expires_in.seconds.since(from)
  end

  def self.past_touch_at(from: Time.current)
    touch_in.seconds.ago(from)
  end

  def self.future_touch_at(from: Time.current)
    touch_in.seconds.since(from)
  end

  def self.expires_in
    MixGlobal.config.expires_in
  end

  def self.touch_in
    MixGlobal.config.touch_in
  end

  def self.fetch_record!(name, **, &)
    fetch_record(name, **, expires: false, &)
  end

  def self.fetch_record(name, **options, &)
    options = options.reverse_merge expires: true
    if block_given?
      if options.delete(:force)
        write(name, yield, **options)
      else
        key = normalize_key(name)
        record = find_or_create_by! id: key do |record|
          record.assign_attributes options.slice(:expires, :expires_in).merge!(id: key, data: yield)
        end
        if record._sync(&).destroyed?
          fetch_record(name, **options, &)
        end
        record
      end
    elsif options[:force]
      raise ArgumentError, "Missing block: Calling `Global#fetch_record` with `force: true` requires a block."
    else
      read_record(name, **options)
    end
  end

  def self.write_record!(*, **, &)
    write_record(*, **, expires: false, &)
  end

  ### Useful statements for the block:
  # - new record --> record.nil?
  # - skip write --> throw :skip_write
  # - rollback   --> throw :abort
  def self.write_record(name, value = nil, **options, &block)
    options = options.reverse_merge expires: true
    block = proc{ value } unless block_given?
    record = fetch_record(name, **options, &block)
    unless record.new?
      record.with_lock do
        catch(:skip_write) do
          record.update! options.slice(:expires, :expires_in).merge!(data: block.call(record))
        end
      end
    end
    record
  rescue ActiveRecord::RecordNotFound
    retry
  end

  def self.read_record(name)
    key = normalize_key(name)
    if (record = find_by(id: key))
      record unless record._sync_stale_state.stale?
    end
  end

  def self.read_records(names)
    case names
    when Array
      keys = names.map{ |name| normalize_key(name) }
      where(id: keys).find_each.with_object({}.to_hwia) do |record, memo|
        memo[key_name(record)] = record unless record._sync_stale_state.stale?
      end
    when String, Regexp
      where(column(:id).matches key_matcher(names)).find_each.with_object({}.to_hwia) do |record, memo|
        memo[key_name(record)] = record unless record._sync_stale_state.stale?
      end
    else
      raise ArgumentError, "Bad type: `Global#read_records` requires names as Array, String or Regexp."
    end
  end

  def self.delete_record(name)
    where(id: normalize_key(name)).delete_all
  end

  def self.delete_records(matcher = nil, *names)
    return 0 if matcher.nil?
    if names.empty?
      case matcher
      when Array          then matcher = GlobalKey.start_with(matcher)
      when String, Regexp then # do nothing
      else raise ArgumentError, "Bad type: `Global#delete_records` requires matcher as Array, String or Regexp."
      end
      where(column(:id).matches key_matcher(matcher)).delete_all
    else
      where(id: [matcher].concat(names).map{ |name| normalize_key(name) }).delete_all
    end
  end

  def self.update_integer!(*, **)
    update_integer(*, **, expires: false)
  end

  def self.update_integer(name, amount, **options)
    raise ArgumentError, "Bad type: `Global#update_integer` requires amount as Integer." unless amount.is_a? Integer

    options = options.reverse_merge expires: true
    key = normalize_key(name)
    if (result = update_counter(key, amount)).nil?
      create! options.slice(:expires, :expires_in).merge!(id: key, data: amount)
      result = amount
    end
    result
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  class << self
    private

    def update_counter(key, amount)
      raise ArgumentError, "Bad value: `Global#update_counter` requires amount != 0." if amount == 0

      operator = amount < 0 ? "-" : "+"
      quoted_column = adapter_class.quote_column_name(:integer)
      updates = ["#{quoted_column} = COALESCE(#{quoted_column}, 0) #{operator} #{amount.abs}"]

      touch_updates = touch_attributes_with_time
      updates << sanitize_sql_for_assignment(touch_updates)

      unscoped.where(id: key).update_all(updates.join(", "), quoted_column)
    end

    def normalize_key(key, server: true)
      # no namespace functionality implemented on purpose --> https://github.com/kickstarter/rack-attack/issues/370
      key = expanded_key(key).full_underscore(GlobalKey::SEPARATOR)
      key = Server.current.id.to_s << GlobalKey::SEPARATOR << key if server
      key
    end

    def expanded_key(key)
      return key.cache_key.to_s if key.respond_to? :cache_key
      case key
      when Array
        key = (key.size > 1) ? key.map{ |element| expanded_key(element) } : key.first
      when Hash
        key = key.sort_by{ |k, _| k.to_s }.map{ |k, v| "#{k}=#{v}" }
      end
      key.to_param
    end

    def key_matcher(pattern)
      regex = pattern.is_a?(Regexp) ? pattern.source : pattern
      regex = "^#{regex}" unless regex.start_with? '^'
      regex = regex.tr('/', GlobalKey::SEPARATOR)
      if regex == '^' || regex.exclude?(GlobalKey::SEPARATOR)
        raise ArgumentError, "Bad value: `Global#key_matcher` pattern /#{regex}/ matches too many records."
      end
      regex[0] = Server.current.id.to_s << GlobalKey::SEPARATOR
      sanitize_matcher /^#{regex}/
    end

    def key_name(record)
      record.id.delete_prefix([record.server_id, GlobalKey::SEPARATOR].join)
    end
  end

  def expirable?
    expires
  end

  def permanent?
    !expirable?
  end

  def expired?
    expirable? && (self.class.future_expires_at(from: updated_at).past? || expires_at&.past?).to_b
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
    case new_type
    when :symbol
      self[:data] = self[:string] = data
    else
      self[:data] = self[data_type] = cast(data)
    end
  end

  def stale?
    destroyed? || changed?
  end

  def _sync
    return self if new?
    _sync_stale_state
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

  def _sync_stale_state
    if expired?
      delete
    elsif expired_touch?
      destroyed! unless touch
    end
    self
  end

  private

  def type_of(data)
    case data
    when Array, Hash             then :json
    when Boolean                 then :boolean
    when Integer                 then :integer
    when Float, BigDecimal       then :decimal
    when Time, Date, DateTime    then :datetime
    when ActiveSupport::Duration then :interval
    when Symbol                  then :symbol
    when String, nil             then :string
    else raise "unsupported data type: #{data.class}"
    end
  end

  def set_defaults
    self.server_id ||= Server.current.id
    self[:data] = case data_type
      when :symbol
        cast(self[:string])
      else
        cast(self[data_type])
      end
    clear_attribute_change(:data)
  end

  def cast(data)
    return data unless data
    case data_type
    when :symbol
      data.to_sym
    else
      data
    end
  end
end
