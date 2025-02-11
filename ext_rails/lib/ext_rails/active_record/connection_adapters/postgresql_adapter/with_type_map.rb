MonkeyPatch.add{['activerecord', 'lib/active_record/connection_adapters/postgresql_adapter.rb', 'a339250635176e8a351c0aad0c1a6b01d6804619b384ea4734af898beccd9fa9']}

module ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::WithTypeMap
  extend ActiveSupport::Concern

  prepended do
    ActiveRecord::Type.register(:regclass, self::OID::Regclass, adapter: :postgresql)
    ActiveRecord::Type.register(:xid, self::OID::Xid, adapter: :postgresql)
  end

  def initialize_type_map(m = type_map)
    super
    m.register_type 'regclass', ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Regclass.new
    m.register_type 'xid', ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Xid.new
  end
end
