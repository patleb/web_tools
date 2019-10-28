module Db
  module Pg
    class Restore < Base
      CSV_MATCHER = /~([A-Za-z_][A-Za-z0-9_]*)\.csv(\.gz)?$/

      def self.args
        super.merge!(
          name:        ['--name=NAME',         'Dump file name (default to dump)'],
          base_dir:    ['--base-dir=BASE_DIR', 'Dump file(s) base directory (default to ENV["RAILS_ROOT"]/db)'],
          includes:    ['--includes=INCLUDES', 'Included tables'],
          staged:      ['--[no-]staged',       'Force restore in 3 phases (pre-data, data, post-data)'],
          timescaledb: ['--[no-]timescaledb',  'Specify if TimescaleDB is used'],
          csv:         ['--[no-]csv',          'Restore from CSV'],
          compress:    ['--[no-]compress',     'Specify if CSV is compressed'],
        )
      end

      def self.defaults
        {
          name: 'dump',
          includes: '',
          base_dir: ExtRake.config.rails_root.join('db'),
        }
      end

      def restore
        options.csv ? copy_from : pg_restore
      end

      private

      # TODO parallelize
      # https://github.com/timescale/timescaledb-parallel-copy
      # http://www.programmersought.com/article/8849706613/
      # https://www.citusdata.com/blog/2016/06/15/copy-postgresql-distributed-tables
      # https://citusdata.com/blog/2017/11/08/faster-bulk-loading-in-postgresql-with-copy/
      # http://www.programmersought.com/article/8849706613/
      # https://stackoverflow.com/questions/14980048/how-to-decompress-with-pigz
      def copy_from
        tables = options.includes.split(',').reject(&:blank?).uniq
        table, compress = csv_file.basename.to_s.match(CSV_MATCHER).captures
        if options.compress || compress
          psql "\\COPY #{tables.first || table} FROM PROGRAM 'unpigz -c #{csv_file}' CSV"
        else
          psql "\\COPY #{tables.first || table} FROM '#{csv_file}' CSV"
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
              pg_restore #{cmd_options} #{"--section=#{section}" if section} #{pg_file}
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

      def pg_file
        "#{dump_path}.pg"
      end

      def csv_file
        dump_path
      end

      def dump_path
        @dump_path ||= Pathname.new(options.base_dir).join(options.name).expand_path
      end
    end
  end
end
