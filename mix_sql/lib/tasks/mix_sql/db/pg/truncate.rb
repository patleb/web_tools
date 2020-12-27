module Db
  module Pg
    class Truncate < Base
      def self.args
        super.merge!(
          includes: ['--includes=INCLUDES', Array, 'Included tables', :required],
        )
      end

      def truncate
        # RESTART IDENTITY
        # ----------------
        # SELECT setval(pg_get_serial_sequence('#{table}', 'id'), COALESCE((SELECT MAX(id) + 1 FROM #{table}), 1), false);
        psql! <<~SQL.squish
          TRUNCATE TABLE #{options.includes.join(', ')} RESTART IDENTITY;
        SQL
      end
    end
  end
end
