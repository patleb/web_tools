module Checks
  module Postgres
    class InvalidConstraint < Base
      attribute :table
      attribute :referenced_table

      def self.list
        db.invalid_constraints.map do |row|
          { id: row[:name], **row.slice(:table, :referenced_table) }
        end
      end

      def error?
        true
      end
    end
  end
end
