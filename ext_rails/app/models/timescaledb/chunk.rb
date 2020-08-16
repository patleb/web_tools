module Timescaledb
  class Chunk < ActiveRecord::Base
    include AsView

    belongs_to :table

    delegate :set_next_chunk_size, to: :table
  end
end
