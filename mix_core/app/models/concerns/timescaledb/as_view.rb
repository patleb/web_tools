module Timescaledb
  module AsView
    extend ActiveSupport::Concern

    included do
      self.table_name_prefix = 'timescaledb_'
      self.primary_key = :id
    end

    def readonly?
      true
    end

    def pretty_total
      total_bytes.to_s(:human_size)
    end

    def pretty_table
      table_bytes.to_s(:human_size)
    end

    def pretty_index
      index_bytes.to_s(:human_size)
    end

    def pretty_toast
      toast_bytes.to_s(:human_size)
    end
  end
end
