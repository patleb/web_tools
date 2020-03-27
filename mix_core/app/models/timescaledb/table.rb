module Timescaledb
  class Table < ActiveRecord::Base
    include AsView

    has_many :chunks

    def set_next_chunk_size(value)
      self.class.connection.exec_query <<-SQL.strip_sql
        SELECT set_chunk_time_interval('#{name}', #{value})::TEXT;
      SQL
    end
  end
end
