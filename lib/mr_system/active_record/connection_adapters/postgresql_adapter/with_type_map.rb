# https://gist.github.com/vollnhals/a7d2ce1c077ae2289056afdf7bba094a

module ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::WithTypeMap
  extend ActiveSupport::Concern

  prepended do
    ActiveRecord::Type.register(:interval, self::OID::Interval, adapter: :postgresql)
    ActiveRecord::Type.register(:regclass, self::OID::Regclass, adapter: :postgresql)
  end

  def initialize_type_map(m = type_map)
    super
    m.register_type 'interval' do |_, _, sql_type|
      precision = extract_precision(sql_type)
      ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Interval.new(precision: precision)
    end
    m.register_type 'regclass', ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Regclass.new
  end

  def configure_connection
    super
    execute('SET intervalstyle = iso_8601', 'SCHEMA')
  end
end
