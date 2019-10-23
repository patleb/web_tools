module Db
  module Pg
    class Restore < Base
      CSV_MATCHER = /^([a-z0-9_]+)(-\d{14})?\.csv(\.gz)?$/

      def self.args
        super.merge!(
          name:        ['--name=NAME',         'Dump file name (default to dump)'],
          base_dir:    ['--base-dir=BASE_DIR', 'Dump file(s) base directory (default to ENV["RAILS_ROOT"]/db)'],
          includes:    ['--includes=INCLUDES', 'Included tables'],
          staged:      ['--[no-]staged',       'Force restore in 3 phases (pre-data, data, post-data)'],
          timescaledb: ['--[no-]timescaledb',  'Specify if TimescaleDB is used'],
          csv:         ['--[no-]csv',          'Restore from CSV'],
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

      def copy_from
        tables = options.includes.split(',').reject(&:blank?).uniq
        csv_files.each do |file|
          table, _timestamp, compress = file.basename.to_s.match(CSV_MATCHER).captures
          next unless tables.empty? || tables.include?(table)
          if compress
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

      def csv_files
        dump_path.children(false)
          .select{ |file| file.basename.to_s.match? CSV_MATCHER }
          .map{ |file| dump_path.join(file) }
      end

      def dump_path
        @dump_path ||= Pathname.new(options.base_dir).join(options.name).expand_path
      end
    end
  end
end
