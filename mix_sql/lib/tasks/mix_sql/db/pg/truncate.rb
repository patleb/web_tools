module Db
  module Pg
    class Truncate < Base
      def self.args
        super.merge!(
          includes: ['--includes=INCLUDES', Array, 'Included tables', :required],
        )
      end

      def truncate
        options.includes.each do |table|
          psql! <<~SQL.squish
            TRUNCATE TABLE #{table};
            SELECT setval(pg_get_serial_sequence('#{table}', 'id'), COALESCE((SELECT MAX(id) + 1 FROM #{table}), 1), false);
          SQL
        end
      end
    end
  end
end
