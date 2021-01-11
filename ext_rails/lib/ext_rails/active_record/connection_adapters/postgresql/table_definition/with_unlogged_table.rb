module ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithUnloggedTable
  def initialize(*, **options)
    super
    @unlogged = true if options[:unlogged]
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.prepend ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithUnloggedTable
