module Db
  module Pg
    class DropAll < Base
      def self.steps
        [:psql_drop_all]
      end

      def psql_drop_all
        sh <<~CMD, verbose: false
          psql --quiet -c "DROP OWNED BY CURRENT_USER;" "#{ExtRake.config.db_url}"
        CMD
      end
    end
  end
end
