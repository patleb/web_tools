MonkeyPatch.add{['activerecord', 'lib/active_record/connection_adapters/postgresql/schema_definitions.rb', '67345bc2286f297de37cf20a5164ce5bda8295f74fb2a12dbdc59e0b229e62bf']}

module ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithUnloggedTable
  def initialize(*, **options)
    super
    @unlogged = true if options[:unlogged]
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.prepend ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition::WithUnloggedTable
