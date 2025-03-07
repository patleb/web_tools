MonkeyPatch.add{['activerecord', 'lib/active_record/attribute_methods.rb', 'fdeaea70c73f617d126e742981ba57708ad1e62e72bfc48ae122d72516fc8bb7']}
MonkeyPatch.add{['activerecord', 'lib/active_record/scoping/default.rb', 'f3ef75dde6646c9285199ca8c4c506d2f50cc65aba1c799ac5282c36a01eb135']}

require_dir __FILE__, 'base'

ActiveRecord::Base.class_eval do
  SKIP_LOCKING_ATTRIBUTES = Set.new([
    'id',
    'updated_at'
  ])
  EXCLUDED_MODEL_SUFFIXES = %w(
    .include.rb
    .prepend.rb
    _admin.rb
    _decorator.rb
    /null.rb
    /base.rb
    /main.rb
  )
  TYPES_HASH = %i(
    virtual_columns_hash
    attribute_types
    columns_hash
  )

  class_attribute :skip_locking_attributes, instance_writer: false, instance_predicate: false, default: SKIP_LOCKING_ATTRIBUTES

  extend MemoizedAt
  include ActiveSupport::LazyLoadHooks::Autorun
  include self::WithArel
  include self::WithDiscard
  prepend self::WithJsonb
  prepend self::WithJsonAttribute
  prepend self::WithNullifyBlanks
  prepend self::WithPartition
  include self::WithPresenter
  prepend self::WithRequiredBelongsTo
  prepend self::WithList
  include self::WithRescuableValidations

  alias_method :decrypted, :read_attribute_before_type_cast
  alias_method :new?, :previously_new_record?

  delegate :slice, :except, to: :attributes_hash

  class << self
    alias_method :without_default_scope, :evaluate_default_scope
    public :without_default_scope

    def scope(name, body, &block)
      super if name.match?(/^[a-z_][a-z0-9_]*$/)
    end
  end

  self.store_base_sti_class = false

  def self.enum!(*, **)
    enum(*, scopes: false, instance_methods: false, with_keyword_access: false, **)
  end

  def self.establish_connection_for(namespace)
    env = :"#{namespace}_#{Rails.env}"
    keys = %i(host port database username)
    config = ActiveRecord::Base.configurations.resolve(env).configuration_hash.slice(*keys)
    default_config = ActiveRecord::Base.configurations.resolve(Rails.env.to_sym).configuration_hash.slice(*keys)
    host, default_host = config.delete(:host), default_config.delete(:host)
    return establish_connection(env) unless config == default_config
    return if host == default_host
    return establish_connection(env) unless Host.domains.has_key? :server
    return if Host.domains[:server].find{ |name, _ip| name == host }&.last == default_host
    establish_connection(env)
  end

  def self.with_raw_connection
    with_connection do |ar_conn|
      yield ar_conn.raw_connection, ar_conn
    end
  end

  def without_default_scope_on_association(name)
    reflection = self.class.reflect_on_association(name)
    reflection.klass.without_default_scope do
      yield(send(name), reflection.klass)
    end
  end

  def self.without_timezone(&block)
    with_timezone('UTC', &block)
  end

  def self.with_timezone(zone, &block)
    old_value = time_zone_aware_attributes
    self.time_zone_aware_attributes = false
    Time.use_zone(zone, &block)
  ensure
    self.time_zone_aware_attributes = old_value
  end

  def self.with_timeout(time_ms, lock_ms = nil, &block)
    if lock_ms
      with_setting('statement_timeout', time_ms) do
        with_setting('lock_timeout', lock_ms, &block)
      end
    else
      with_setting('statement_timeout', time_ms, &block)
    end
  end

  def self.with_setting(name, value)
    transaction do
      connection.exec_query "SET LOCAL #{name} = #{connection.quote(value)};"
      yield
    end
  end

  def self.encoding
    @encoding ||= connection.select_one("SELECT ''::text AS str;").values.first.encoding
  end

  def self.sanitize_matcher(regex)
    like = sanitize_sql_like(regex.source)
    like.gsub! "\\/", '/'
    like.gsub! '.*', '%'
    like.gsub! '.', '_'
    like.delete_prefix!('^') || like.prepend('%')
    like.delete_suffix!('$') || like.concat('%')
  end

  def self.quote_columns(*names)
    names.map{ |name| quote_column(name) }
  end

  def self.quote_column(name)
    name, type = name.to_s.split('::')
    table, column = name.split('.', 2)
    if column
      table = adapter_class.quote_table_name(table)
    else
      column, table = table, quoted_table_name
    end
    result = [table, adapter_class.quote_column_name(column)].join('.')
    result = [result, type].join('::') if type
    result.sql_safe
  end

  def self.dequeue_all(*columns, limit: nil)
    pk = "#{quoted_table_name}.#{quoted_primary_key}"
    query = <<-SQL.strip_sql
      DELETE FROM #{quoted_table_name}
      WHERE #{pk} IN (
        SELECT #{pk} FROM #{quoted_table_name}
        #{ yield(*quote_columns(*columns)) }
        FOR UPDATE SKIP LOCKED
        #{"LIMIT #{limit}" if limit}
      )
      RETURNING *;
    SQL
    uncached{ find_by_sql(query) }
  end

  def self.dequeue(*columns)
    pk = "#{quoted_table_name}.#{quoted_primary_key}"
    query = <<-SQL.strip_sql
      DELETE FROM #{quoted_table_name}
      WHERE #{pk} = (
        SELECT #{pk} FROM #{quoted_table_name}
        #{ yield(*quote_columns(*columns)) }
        FOR UPDATE SKIP LOCKED
        LIMIT 1
      )
      RETURNING *;
    SQL
    uncached{ find_by_sql(query).first }
  end

  if Rails.env.test?
    def self.now_sql
      connection.quote(connection.type_cast(Time.current.utc))
    end
  else
    def self.now_sql
      'CURRENT_TIMESTAMP'
    end
  end

  def self.viable_models
    @viable_models ||= Rails.viable_names('models', ExtRails.config.excluded_models, EXCLUDED_MODEL_SUFFIXES)
  end

  def self.sti_parents
    @sti_parents ||= begin
      all = viable_models.each_with_object({}) do |model_name, parents|
        with_model(model_name) do |model|
          if model.sti? && model.base_class?
            parents[model.name] ||= Set.new(model.inherited_types)
          end
        end
      end
      all.transform_values!(&:to_a)
      all
    end
  end

  def self.polymorphic_parents
    @polymorphic_parents ||= begin
      all = viable_models.each_with_object({}) do |model_name, parents|
        with_model(model_name) do |model|
          model.reflect_on_all_associations.each do |association|
            if association.options[:polymorphic]
              (parents[model.name] ||= {})[association.name] ||= Set.new
            elsif (as = association.options[:as])
              next if association.through_reflection?
              ((parents[association.klass.name] ||= {})[as.to_sym] ||= Set.new) << model
            end
          end
        end
      end
      all.each_value{ |associations| associations.transform_values!(&:to_a) }
      all
    end
  end

  def self.sti?
    has_attribute?(inheritance_column)
  end

  def self.inherited_types
    @inherited_types ||= base_class.descendants.reject(&:abstract_class?).select{ |klass| klass.connection == connection }
  end

  def self.types_hash
    @types_hash ||= TYPES_HASH.each_with_object({}.to_hwka) do |attributes_method, hash|
      hash.merge! public_send(attributes_method) if respond_to? attributes_method
    end
  end

  def self.with_model(model_name)
    model = begin
      model_name.to_const!
    rescue LoadError, NameError
      puts model_name if Rails.env.development?
      return
    end
    return if     model < ::ActiveType::Object
    return unless model < ::ActiveRecord::Base
    return if     model.abstract_class?
    return unless model.connection == connection
    yield model
  end
  private_class_method :with_model

  def attributes_hash
    hash = @attributes.to_hash
    hash.merge! attribute_aliases.except('id_value').transform_values{ |v| hash[v] }
    hash.to_hwka
  end

  def destroyed!
    @destroyed = true
    freeze
  end

  def can_destroy?
    self.class.reflect_on_all_associations.all? do |association|
      [:restrict_with_error, :restrict_with_exception].exclude?(association.options[:dependent]) \
        || (association.macro == :has_one && public_send(association.name).nil?) \
        || (association.macro == :has_many && public_send(association.name).empty?)
    end
  end

  def locking_enabled?
    super && changed.any?{ |attribute| skip_locking_attributes.exclude? attribute }
  end
end
