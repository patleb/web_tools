module Checks
  module Postgres
    class Constraint < Base
      attribute :table
      attribute :referenced_table

      def self.list
        db.invalid_constraints.map do |row|
          { id: row[:name], **row.slice(:table, :referenced_table) }
        end
      end

      def self.issues
        { constraint: any? }
      end
    end
  end
end
