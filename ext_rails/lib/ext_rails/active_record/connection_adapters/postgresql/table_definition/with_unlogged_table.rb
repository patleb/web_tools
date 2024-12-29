MonkeyPatch.add{['activerecord', 'lib/active_record/connection_adapters/postgresql/schema_definitions.rb', '1522b88bf7a5756c60ef39b0bde3673da23a88579e1b93e2aacb7542ca0556d2']}

module ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithUnloggedTable
  def initialize(*, **options)
    super
    @unlogged = true if options[:unlogged]
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.prepend ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithUnloggedTable
