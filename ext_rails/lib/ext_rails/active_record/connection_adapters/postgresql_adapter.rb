require 'active_record/connection_adapters/postgresql_adapter'
require 'ext_rails/sql'
require_dir __FILE__, 'postgresql'
require_dir __FILE__, 'postgresql_adapter'

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
  include self::WithReference
  prepend self::WithReturningColumn
  include self::WithUnaccent
  prepend self::WithTypeMap

  def type_exists?(name)
    select_value("SELECT COUNT(*) FROM pg_type WHERE typname = '#{name}'").to_i > 0
  end
  alias_method :enum_exists?, :type_exists?

  def function_exists?(name)
    select_value("SELECT COUNT(*) FROM pg_proc WHERE proname = '#{name}'").to_i > 0
  end

  def trigger_exists?(table, name)
    select_value("SELECT COUNT(*) FROM pg_trigger WHERE NOT tgisinternal AND tgrelid = '#{table}'::regclass AND tgname = '#{name}'").to_i > 0
  end

  def with(**options)
    (Thread.current[:sql_options] ||= {})[self] = options
    yield
  ensure
    Thread.current[:sql_options].delete(self)
  end
end
