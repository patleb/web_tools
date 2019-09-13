module Db
  module Pg
    class Truncate < Base
      def self.steps
        [:psql_truncate]
      end

      def self.args
        super.merge!(
          includes: ['--includes=INCLUDES', 'Included tables'],
        )
      end

      def psql_truncate
        if options.includes.blank?
          raise "comma separated tables must be specified through --includes option"
        end

        only = options.includes.split(',').reject(&:blank?).map do |table|
          <<~SQL
            TRUNCATE TABLE #{table};
            SELECT setval(pg_get_serial_sequence('#{table}', 'id'), COALESCE((SELECT MAX(id) + 1 FROM #{table}), 1), false);
          SQL
        end.join(' ').gsub(/\n/, ' ')

        run_sql(only)
      end
    end
  end
end
