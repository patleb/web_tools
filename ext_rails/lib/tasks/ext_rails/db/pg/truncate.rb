module Db
  module Pg
    class Truncate < Base
      def self.args
        super.merge!(
          includes: ['--includes=INCLUDES', Array, 'Included tables', :required],
          only:     ['--[no-]only',                'Do not truncate related tables/partitions'],
          cascade:  ['--[no-]cascade',             'Truncate all tables with foreign key reference']
        )
      end

      def truncate
        # MANUAL SEQUENCE RESTART
        # -----------------------
        # SELECT setval(pg_get_serial_sequence('#{table}', 'id'), (SELECT COALESCE(MAX(id), 0) + 1 FROM #{table}), FALSE);
        psql! <<~SQL.squish
          TRUNCATE TABLE #{'ONLY' if options.only} #{options.includes.join(', ')} RESTART IDENTITY #{'CASCADE' if option.cascade};
        SQL
      end
    end
  end
end
