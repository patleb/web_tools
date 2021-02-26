module ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithTimestamp
  def timestamps(**options)
    options = { default: -> { 'CURRENT_TIMESTAMP' } }.merge(options)
    super(**options)
  end

  def timestamp(name, **options)
    options = { default: -> { 'CURRENT_TIMESTAMP' } }.merge(options)
    options[:precision] = 6 if !options.key?(:precision) && @conn.supports_datetime_with_precision?
    super(name, **options)
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.prepend ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithTimestamp
