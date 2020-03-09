class TimescaledbChunk < ActiveRecord::Base
  self.primary_key = :id

  belongs_to :table, foreign_key: :table_name, class_name: 'TimescaledbTable'

  def readonly?
    true
  end
end if Setting[:timescaledb_enabled]
