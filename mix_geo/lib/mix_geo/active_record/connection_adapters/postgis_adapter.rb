module ActiveRecord
  module ConnectionAdapters
    PostGISAdapter.class_eval do
      ActiveRecord::Type.add_modifier({ array: true }, PostgreSQLAdapter::OID::Array, adapter: :postgis)
      ActiveRecord::Type.add_modifier({ range: true }, PostgreSQLAdapter::OID::Range, adapter: :postgis)
      ActiveRecord::Type.register(:bit, PostgreSQLAdapter::OID::Bit, adapter: :postgis)
      ActiveRecord::Type.register(:bit_varying, PostgreSQLAdapter::OID::BitVarying, adapter: :postgis)
      ActiveRecord::Type.register(:binary, PostgreSQLAdapter::OID::Bytea, adapter: :postgis)
      ActiveRecord::Type.register(:cidr, PostgreSQLAdapter::OID::Cidr, adapter: :postgis)
      ActiveRecord::Type.register(:date, PostgreSQLAdapter::OID::Date, adapter: :postgis)
      ActiveRecord::Type.register(:datetime, PostgreSQLAdapter::OID::DateTime, adapter: :postgis)
      ActiveRecord::Type.register(:decimal, PostgreSQLAdapter::OID::Decimal, adapter: :postgis)
      ActiveRecord::Type.register(:enum, PostgreSQLAdapter::OID::Enum, adapter: :postgis)
      ActiveRecord::Type.register(:hstore, PostgreSQLAdapter::OID::Hstore, adapter: :postgis)
      ActiveRecord::Type.register(:inet, PostgreSQLAdapter::OID::Inet, adapter: :postgis)
      ActiveRecord::Type.register(:interval, PostgreSQLAdapter::OID::Interval, adapter: :postgis)
      ActiveRecord::Type.register(:jsonb, PostgreSQLAdapter::OID::Jsonb, adapter: :postgis)
      ActiveRecord::Type.register(:money, PostgreSQLAdapter::OID::Money, adapter: :postgis)
      ActiveRecord::Type.register(:point, PostgreSQLAdapter::OID::Point, adapter: :postgis)
      ActiveRecord::Type.register(:legacy_point, PostgreSQLAdapter::OID::LegacyPoint, adapter: :postgis)
      ActiveRecord::Type.register(:uuid, PostgreSQLAdapter::OID::Uuid, adapter: :postgis)
      ActiveRecord::Type.register(:vector, PostgreSQLAdapter::OID::Vector, adapter: :postgis)
      ActiveRecord::Type.register(:xml, PostgreSQLAdapter::OID::Xml, adapter: :postgis)

      ActiveRecord::Type.register(:regclass, PostgreSQLAdapter::OID::Regclass, adapter: :postgis)
      ActiveRecord::Type.register(:xid, PostgreSQLAdapter::OID::Xid, adapter: :postgis)
    end
  end
end
