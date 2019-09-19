module Db
  module Pg
    class DropAll < Base
      def self.steps
        [:psql_drop_all]
      end

      def psql_drop_all
        psql 'DROP OWNED BY CURRENT_USER'
      end
    end
  end
end
