class TimescaledbTable < ActiveRecord::Base
  include AsTimescaledbView

  has_many :chunks, foreign_key: :table_id, class_name: 'TimescaledbChunk', inverse_of: :table

  def set_next_chunk_size(value)
    self.class.connection.exec_query <<-SQL.strip_sql
      SELECT set_chunk_time_interval('#{name}', #{value})::TEXT;
    SQL
  end
end if Setting[:timescaledb_enabled]
