module Checks
  module Postgres
    class Constraint < Base
      attribute :table
      attribute :referenced_table

      def self.list
        db.invalid_constraints.select_map do |row|
          next unless public? row, :schema, :referenced_schema
          { id: row[:name], **row.slice(:table, :referenced_table) }
        end
      end

      def self.issues
        { constraint: any? }
      end
    end
  end
end
