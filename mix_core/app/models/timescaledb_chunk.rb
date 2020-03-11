class TimescaledbChunk < ActiveRecord::Base
  include AsTimescaledbView

  MAX_BYTES = Setting[:timescaledb_max_bytes]

  belongs_to :table, foreign_key: :table_id, class_name: 'TimescaledbTable'

  delegate :set_next_chunk_size, to: :table
end if Setting[:timescaledb_enabled]
