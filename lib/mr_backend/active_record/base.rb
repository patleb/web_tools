require_rel 'base'

ActiveRecord::Base.class_eval do
  include self::WithInheritedTypes
  include self::WithRescuableValidations

  delegate :url_helpers, to: 'Rails.application.routes'

  def self.virtual?
    false
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

  def self.total_size
    result = connection.exec_query(<<-SQL.strip_sql)
      SELECT pg_database.datname AS "name", pg_size_pretty(pg_database_size(pg_database.datname)) AS "size"
      FROM pg_database;
    SQL
    result.find{ |entry| entry['name'] == connection_config[:database] }['size']
  end

  def self.size
    sizes[table_name]
  end

  def self.sizes(order_by_name = false)
    # TODO include MemoizedAt
    result = connection.exec_query(<<-SQL.strip_sql)
      SELECT relname AS "name", pg_size_pretty(pg_total_relation_size(relid)) AS "size"
      FROM pg_catalog.pg_statio_user_tables
      ORDER BY #{order_by_name ? 'name' :'pg_total_relation_size(relid) DESC'};
    SQL
    result.each_with_object({}.with_indifferent_access) do |entry, memo|
      memo[entry['name']] = entry['size']
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
end
