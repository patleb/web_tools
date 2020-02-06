module MixBackup
  module Backup
    class Partition < Base
      include Pgslice

      def self.steps
        super + %i(
          create_new_partition
          remove_old_partition
        )
      end

      def self.args
        super.merge!(
          table:  ['--table=TABLE',   'Partitioned table'],
          month:  ['--month=MONTH',   'Month in format YYYYMM (ex.: 201801)'],
          day:    ['--day=DAY',       'Day in format YYYYMMDD (ex.: 20180102)'],
          future: ['--future=FUTURE', 'Number of future partitions (0 by default)']
        )
      end

      def backup_env
        super << "PARTITION=#{partition}"
      end

      protected

      def create_new_partition
        sh_clean "#{pgslice_cmd} add_partitions #{options.table} --future #{options.future || 0}", verbose: false
      end

      def remove_old_partition
        ExtRake.config.db_adapter.connection.exec_query("DROP TABLE #{partition}")
      end

      def partition
        "#{options.table}_#{options.month || options.day}"
      end
    end
  end
end
