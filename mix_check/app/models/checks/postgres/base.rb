module Checks
  module Postgres
    class Base < Checks::Base
      def self.database_indexes
        m_access(:database_indexes) do
          database.indexes
        end
      end

      def self.database_size
        m_access(:database_size) do
          database.database_size
        end
      end

      def self.database
        PgHero.primary_database
      end
    end
  end
end
