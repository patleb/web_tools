module ActiveRecord
  module ConnectionAdapters
    PostGISAdapter.class_eval do
      ActiveRecord::Type.register(:jsonb, PostgreSQLAdapter::OID::Jsonb, adapter: :postgis)
    end
  end
end
