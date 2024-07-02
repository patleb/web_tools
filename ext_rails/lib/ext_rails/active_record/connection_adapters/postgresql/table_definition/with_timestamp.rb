module ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithTimestamp
  def timestamps(**options)
    options = { default: -> { 'CURRENT_TIMESTAMP' } }.merge(options)
    super(**options)
  end

  def timestamp(name, **options)
    options = { default: -> { 'CURRENT_TIMESTAMP' } }.merge(options)
    super(name, **options)
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.prepend ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithTimestamp
