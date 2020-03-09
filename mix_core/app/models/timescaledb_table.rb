class TimescaledbTable < ActiveRecord::Base
  self.primary_key = :name

  has_many :chunks, foreign_key: :table_name, class_name: 'TimescaledbChunk'

  def readonly?
    true
  end

  def set_chunk_time_interval(value)
    self.class.connection.exec_query <<-SQL.strip_sql
      SELECT set_chunk_time_interval('#{name}', #{value});
    SQL
  end
end if Setting[:timescaledb_enabled]
