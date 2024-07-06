MonkeyPatch.add{['activerecord', 'lib/active_record/connection_adapters/postgresql_adapter.rb', 'd8c851a3c08445e649e35752a08eb0e86549deaaabdf8214a7d50c64a18fabf5']}

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
