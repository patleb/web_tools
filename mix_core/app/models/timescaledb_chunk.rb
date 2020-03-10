class TimescaledbChunk < ActiveRecord::Base
  include AsTimescaledbView

  MAX_CHUNK_BYTES = Setting[:timescaledb_max_bytes]

  belongs_to :table, foreign_key: :table_id, class_name: 'TimescaledbTable'
end if Setting[:timescaledb_enabled]
