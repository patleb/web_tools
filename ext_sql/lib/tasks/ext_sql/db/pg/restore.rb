module Db
  module Pg
    class Restore < Base
      def self.args
        super.merge!(
          name:        ['--name=NAME',         'Dump name (default to dump)'],
          base_dir:    ['--base-dir=BASE_DIR', 'Dump file base directory (default to ENV["RAILS_ROOT"]/db(/dump for CSV))'],
          includes:    ['--includes=INCLUDES', 'Included tables'],
          staged:      ['--[no-]staged',       'Force restore in 3 phases (pre-data, data, post-data)'],
          timescaledb: ['--[no-]timescaledb',  'Specify if TimescaleDB is used'],
          csv:         ['--[no-]csv',          'Dump as CSV'],
          compress:    ['--[no-]compress',     'Specify if the resulting CSV is compressed (default to true)'],
        )
      end

      def self.defaults
        {
          name: 'dump',
          includes: '',
          base_dir: ExtRake.config.rails_root.join('db'),
          compress: true,
        }
      end

      def restore
        if options.csv
          copy_from
        else
          pg_restore
        end
      end

      private

      def copy_from
        dump_dir = Pathname.new(options.base_dir).join(options.name)
        tables = options.includes.split(',').reject(&:blank?).uniq
        tables.each do |table|
          file = dump_file(dump_dir, table)
          if options.compress
            psql "\\COPY #{table} FROM PROGRAM 'unpigz -c #{file}' CSV"
          else
            psql "\\COPY #{table} FROM '#{file}' CSV"
          end
        end
      end

      def pg_restore
        with_config do |host, db, user, pwd|
          if options.includes.present?
            only = options.includes.split(',').reject(&:blank?)
          end
          cmd_options = <<~CMD.squish
            --verbose
            --host #{host}
            --username #{user}
            #{self.class.pg_options}
            --no-owner
            --no-acl
            #{only.map{ |table| "--table='#{table}'" }.join(' ')}
            --dbname #{db}
          CMD
          pre_restore_timescaledb if options.timescaledb
          sections = staged ? %w(pre-data data post-data) : [false]
          sections.each do |section|
            cmd = <<~CMD
              export PGPASSWORD=#{pwd};
              pg_restore #{cmd_options} #{"--section=#{section}" if section} #{options.base_dir}/#{options.name}.pg
            CMD
            _stdout, stderr, _status = Open3.capture3(cmd)
            notify!(cmd, stderr) if notify?(stderr)
          end
          post_restore_timescaledb if options.timescaledb
        end
      end

      def pre_restore_timescaledb
        psql(<<-SQL.strip_sql)
          CREATE EXTENSION IF NOT EXISTS timescaledb;
          SELECT timescaledb_pre_restore();
        SQL
      end

      def post_restore_timescaledb
        psql(<<-SQL.strip_sql)
          SELECT timescaledb_post_restore();
        SQL
      end

      def staged
        options.staged || options.timescaledb
      end

      def dump_file(dump_dir, table)
        "#{dump_dir.join(table)}.csv#{'.gz' if options.compress}"
      end
    end
  end
end
