module Checks
  module Postgres
    class Sequence < Base
      attribute :table
      attribute :column
      attribute :last_value, :integer
      attribute :max_value, :integer

      def self.list
        db.sequences.select_map do |row|
          next unless row[:readable]
          { id: row[:sequence], **row.slice(:table, :column, :last_value, :max_value) }
        end
      end

      def danger?
        last_value && (last_value / max_value.to_f > 0.9)
      end

      def left
        last_value && (max_value - last_value)
      end

      alias_method :danger_error?, :danger?
    end
  end
end
