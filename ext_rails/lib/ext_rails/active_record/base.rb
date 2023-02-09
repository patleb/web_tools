require_rel 'base'

ActiveRecord::Base.class_eval do
  class_attribute :skip_locking_attributes, instance_writer: false, instance_predicate: false,
    default: Set.new(['id', 'updated_at'])

  extend MemoizedAt
  include ActiveSupport::LazyLoadHooks::Autorun
  include self::WithArel
  prepend self::WithCreateState
  include self::WithDiscard
  prepend self::WithJsonb
  prepend self::WithJsonAttribute
  include self::WithNullifyBlanks
  include self::WithPartition
  prepend self::WithRequiredBelongsTo
  prepend self::WithList
  include self::WithRescuableValidations
  include self::WithViableModels

  nullify_blanks nullables_only: false

  alias_method :decrypted, :read_attribute_before_type_cast

  class << self
    alias_method :without_default_scope, :evaluate_default_scope
    public :without_default_scope

    def scope(name, body, &block)
      super if name.match?(/^[a-z_][a-z0-9_]*$/)
    end
  end

  def self.with_raw_connection
    with_connection do |ar_conn|
      yield ar_conn.raw_connection, ar_conn
    end
  end

  def self.with_connection(&block)
    connection_pool.with_connection(&block)
  end

  def without_default_scope_on_association(name)
    reflection = self.class.reflect_on_association(name)
    reflection.klass.without_default_scope do
      yield(send(name), reflection.klass)
    end
  end

  def self.without_time_zone(&block)
    with_time_zone('UTC', &block)
  end

  def self.with_time_zone(zone, &block)
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

  def self.timescaledb_tables
    @timescaledb_tables ||= Setting[:timescaledb_enabled] ? connection.select_rows(<<-SQL.strip_sql).to_h : {}
      SELECT table_name AS name, id FROM _timescaledb_catalog.hypertable
    SQL
  end

  def self.sanitize_matcher(regex)
    like = sanitize_sql_like(regex.source).gsub "\\/", '/'
    like.gsub!('.*', '%')
    like.gsub!('.', '_')
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
      table = connection.quote_table_name(table)
    else
      column, table = table, quoted_table_name
    end
    result = [table, connection.quote_column_name(column)].join('.')
    result = [result, type].join('::') if type
    result.sql_safe
  end

  def self.shared_buffers
    @shared_buffers ||= connection.select_value(<<-SQL.strip_sql)
      SELECT setting::BIGINT * pg_size_bytes(unit) AS bytes FROM pg_settings WHERE name = 'shared_buffers'
    SQL
  end

  def self.pretty_total_size
    total_size.to_s(:human_size)
  end

  def self.total_size
    m_access(__method__, timeout: 300) do
      result = connection.select_rows(<<-SQL.strip_sql)
        SELECT pg_database.datname AS name, pg_database_size(pg_database.datname) AS size FROM pg_database
      SQL
      result.find{ |(name, _size)| name == connection_config[:database] }.last
    end
  end

  def self.pretty_size
    size.to_s(:human_size)
  end

  def self.size
    sizes[table_name]
  end

  def self.pretty_sizes(**options)
    sizes(**options).transform_values(&:to_s.with(:human_size))
  end

  # TODO doesn't work with native partitions
  def self.sizes(order_by_name: false, indexes: false)
    m_access(__method__, order_by_name, indexes, timeout: 300) do
      size = indexes ? 'pg_indexes_size(relid)' :'pg_total_relation_size(relid)'
      result = connection.select_rows(<<-SQL.strip_sql)
        SELECT relname AS name, #{size} AS size
        FROM pg_catalog.pg_statio_user_tables
        WHERE relname NOT LIKE '\_hyper\_%'
        ORDER BY #{order_by_name ? 'name' : "#{size} DESC"};
      SQL
      result = result.each_with_object({}.with_keyword_access){ |(name, size), h| h[name] = size }

      if Setting[:timescaledb_enabled]
        timescaledb_tables.each do |name, id|
          result[name] = Timescaledb::Table.find(id).total_bytes
        end
        result = result.sort_by(&:last).reverse.to_h.with_keyword_access
      end

      result
    end
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

  # TODO integrate with RailsAdmin
  def can_destroy?
    self.class.reflect_on_all_associations.all? do |assoc|
      [:restrict_with_error, :restrict_with_exception].exclude?(assoc.options[:dependent]) \
        || (assoc.macro == :has_one && self.send(assoc.name).nil?) \
        || (assoc.macro == :has_many && self.send(assoc.name).empty?)
    end
  end

  def slice(*methods)
    methods.map!{ |method| [method, public_send(method)] }.to_h.with_keyword_access
  end

  def except(*methods)
    slice(attributes.keys.except(*methods.map!(&:to_s)))
  end

  def locking_enabled?
    super && changed.any?{ |attribute| skip_locking_attributes.exclude? attribute }
  end

  def destroyed!
    @destroyed = true
    freeze
  end
end
