module Db
  module Pg
    class Truncate < Base
      def self.args
        super.merge!(
          includes: ['--includes=INCLUDES', Array, 'Included tables'],
        )
      end

      def truncate
        if options.includes.blank?
          raise "comma separated tables must be specified through --includes option"
        end

        truncate_tables = options.includes.map do |table|
          <<~SQL
            TRUNCATE TABLE #{table};
            SELECT setval(pg_get_serial_sequence('#{table}', 'id'), COALESCE((SELECT MAX(id) + 1 FROM #{table}), 1), false);
          SQL
        end.join(' ').squish

        psql! truncate_tables
      end
    end
  end
end
