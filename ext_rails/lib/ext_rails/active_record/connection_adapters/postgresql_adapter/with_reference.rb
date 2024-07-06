### References
# http://shuber.io/porting-activerecord-counter-cache-behavior-to-postgres/
# https://dev.to/riter/sql-on-rails-concept-1f5m
module ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::WithReference
  def create_function_touch
    exec_query Sql.create_touch
  end

  def drop_function_touch
    exec_query Sql.drop_touch
  end

  def add_touch(...)
    exec_query Sql.create_touch_trigger(...)
  end

  def remove_touch(...)
    exec_query Sql.drop_touch_trigger(...)
  end

  def create_function_counter_cache
    exec_query Sql.create_counter_cache
  end

  def drop_function_counter_cache
    exec_query Sql.drop_counter_cache
  end

  def add_counter_cache(...)
    exec_query Sql.create_counter_cache_trigger(...)
  end

  def remove_counter_cache(...)
    exec_query Sql.drop_counter_cache_trigger(...)
  end
end
