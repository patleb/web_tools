module Checks
  module Postgres
    class Sequence < Base
      attribute :schema
      attribute :table
      attribute :column
      attribute :max_value, :integer
      attribute :last_value, :integer

      def self.list
          database.sequences.select{ |s| s[:readable] }.map do |row|
          { id: row[:sequence], schema: row[:table_schema], **row.slice(:table, :column, :max_value, :last_value) }
        end
      end

      def self.issues
        { sequence: any?(&:danger?) }
      end

      def self.stats
        { sequence: all.select_map{ |item| [item.id, { left: item.left } ] if item.danger? }.to_h }
      end

      def danger?
        last_value && (last_value / max_value.to_f > 0.9)
      end

      def left
        last_value && (max_value - last_value)
      end
    end
  end
end
