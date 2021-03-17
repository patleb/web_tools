module ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::WithTypeMap
  extend ActiveSupport::Concern

  prepended do
    ActiveRecord::Type.register(:regclass, self::OID::Regclass, adapter: :postgresql)
  end

  def initialize_type_map(m = type_map)
    super
    m.register_type 'regclass', ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Regclass.new
  end
end
