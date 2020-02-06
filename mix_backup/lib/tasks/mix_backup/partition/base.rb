module MixBackup
  module Partition
    class Base < Base
      include Pgslice

      class Failed < ::StandardError; end

      def self.steps
        %i(
          prep_table
          add_partitions
          fill_partitions
          analyze_partitions
          swap_table
          fill_swapped_table
          backup_retired_table
          drop_retired_table
        )
      end

      def self.args
        {
          table:      ['--table=TABLE',     'Partitioned table'],
          column:     ['--column=COLUMN',   'Range column'],
          period_day: ['--[no-]period-day', 'Partition by day, otherwise by month'],
          past:       ['--past=PAST',       'Number of past partitions (0 by default)'],
          future:     ['--future=FUTURE',   'Number of future partitions (0 by default)'],
          db:         ['--db=DB',           'DB type (ex.: --db=record would use Record::Base connection'],
        }
      end

      def self.gemfile
        'Gemfile'
      end

      protected

      def prep_table
        sh_clean "#{pgslice_cmd} prep #{options.table} #{options.column} #{options.period_day ? 'day' : 'month'}", verbose: false
      end

      def add_partitions
        sh_clean "#{pgslice_cmd} add_partitions #{options.table} --intermediate --past #{options.past || 0} --future #{options.future || 0}", verbose: false
      end

      def fill_partitions
        sh_clean "#{pgslice_cmd} fill #{options.table}", verbose: false
      end

      def analyze_partitions
        sh_clean "#{pgslice_cmd} analyze #{options.table}", verbose: false
      end

      def swap_table
        sh_clean "#{pgslice_cmd} swap #{options.table}", verbose: false
      end

      def fill_swapped_table
        sh_clean "#{pgslice_cmd} fill #{options.table} --swapped", verbose: false
      end

      def backup_retired_table
        sh "pg_dump -c -Fc -t #{options.table}_retired #{ExtRake.config.db_url} > db/#{options.table}_retired.dump", verbose: false
      end

      def drop_retired_table
        ExtRake.config.db_adapter.connection.exec_query("DROP TABLE #{options.table}_retired")
      end
    end
  end
end
