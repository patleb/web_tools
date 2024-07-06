module Sql
  require_dir __FILE__, 'sql', sort: true

  include self::Reference

  def self.max_index_name_size
    62
  end

  def self.slice(name, keys)
    keys.map{ |key| "'#{key}', #{name}->'#{key}'" }.join(', ')
  end

  def self.destruct(names)
    names.map{ |name| "'#{name}', #{name}" }.join(', ')
  end

  def self.value_changed?(variable)
    <<-SQL.strip_sql
      SELECT #{variable}_was IS NULL AND #{variable} IS NOT NULL
          OR #{variable}_was IS NOT NULL AND #{variable} IS NULL
          OR #{variable}_was != #{variable} INTO #{variable}_changed;
    SQL
  end

  def self.execute(...)
    <<-SQL.strip_sql
      EXECUTE #{send(...)};
    SQL
  end

  def self.debug(*rb_vars, pg_vars: [], record: 'NEW', **)
    return unless ExtRails.config.sql_debug?
    if pg_vars.any?
      pg_vars_values = "{#{' %' * pg_vars.size} }"
      pg_vars_names = ", #{pg_vars.join(', ')}"
    end
    <<-SQL.strip_sql
      RAISE NOTICE '#{record} % % [#{rb_vars.join(', ')}] #{pg_vars_values}', _debug, #{record}#{pg_vars_names};
    SQL
  end

  def self.debug_var
    <<-SQL.strip_sql if ExtRails.config.sql_debug?
      _debug RECORD;
    SQL
  end

  def self.debug_init
    <<-SQL.strip_sql if ExtRails.config.sql_debug?
      _debug = ROW(NULL);
    SQL
  end

  def self.get_value_cmd(column, variable, record: 'NEW', **)
    <<-SQL.compile_sql
      SELECT ($1).[#{column}] [INTO #{variable}] [USING #{record}]
    SQL
  end
  private_class_method :get_value_cmd
end
