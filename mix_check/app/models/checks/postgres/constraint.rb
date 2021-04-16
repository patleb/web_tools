module Checks
  module Postgres
    class Constraint < Base
      attribute :schema
      attribute :table
      attribute :referenced_schema
      attribute :referenced_table

      def self.list
        database.invalid_constraints.map do |row|
          { id: row.delete(:name), **row }
        end
      end

      def self.issues
        { constraint: any? }
      end
    end
  end
end
