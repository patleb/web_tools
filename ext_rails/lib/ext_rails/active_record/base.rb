require_rel 'base'

ActiveRecord::Base.class_eval do
  extend MemoizedAt
  include ActiveSupport::LazyLoadHooks::Autorun
  include self::WithArel
  include self::WithDiscard
  prepend self::WithJsonAttribute
  include self::WithList
  include self::WithNullifyBlanks
  prepend self::WithRequiredBelongsTo
  include self::WithRescuableValidations
  include self::WithViableModels

  SKIP_LOCKING = Set.new(%w(
    id
    updated_at
    updater_id
  ))

  nullify_blanks nullables_only: false

  delegate :url_helpers, to: 'Rails.application.routes'

  class << self
    alias_method :without_default_scope, :evaluate_default_scope
    public :without_default_scope
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
    table, column = name.to_s.split('.', 2)
    if column
      table = connection.quote_table_name(table)
    else
      column, table = table, quoted_table_name
    end
    column, type = column.split('::')
    result = [table, connection.quote_column_name(column)].join('.')
    result = [result, type].join('::') if type
    result.sql_safe
  end

  def self.pretty_total_size
    total_size.to_s(:human_size)
  end

  def self.total_size
    m_access(:total_size, threshold: 300) do
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

  def self.pretty_sizes(*options)
    sizes(*options).transform_values(&:to_s.with(:human_size))
  end

  def self.sizes(order_by_name: false, indexes: false)
    m_access(:sizes, order_by_name, indexes, threshold: 300) do
      size = indexes ? 'pg_indexes_size(relid)' :'pg_total_relation_size(relid)'
      result = connection.select_rows(<<-SQL.strip_sql)
        SELECT relname AS name, #{size} AS size
        FROM pg_catalog.pg_statio_user_tables
        WHERE relname NOT LIKE '\_hyper\_%'
        ORDER BY #{order_by_name ? 'name' : "#{size} DESC"};
      SQL
      result = result.each_with_object({}.with_indifferent_access){ |(name, size), h| h[name] = size }

      if Setting[:timescaledb_enabled]
        timescaledb_tables.each do |name, id|
          result[name] = Timescaledb::Table.find(id).total_bytes
        end
        result = result.sort_by(&:last).reverse.to_h.with_indifferent_access
      end

      result
    end
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

  # TODO integrate with RailsAdmin
  def can_destroy?
    self.class.reflect_on_all_associations.all? do |assoc|
      [:restrict_with_error, :restrict_with_exception].exclude?(assoc.options[:dependent]) \
        || (assoc.macro == :has_one && self.send(assoc.name).nil?) \
        || (assoc.macro == :has_many && self.send(assoc.name).empty?)
    end
  end

  def except(*methods)
    attributes.with_indifferent_access.except!(*methods.flatten)
  end

  def new?
    # TODO id.nil? or !persisted?
    @_new
  end

  def new!
    @_new = true
    self
  end

  def destroyed!
    @destroyed = true
    freeze
  end

  def locking_enabled?
    super && changed.any?{ |attribute| SKIP_LOCKING.exclude? attribute }
  end
end
