module Db
  module Pg
    class Restore < Base
      CSV_MATCHER = /^([a-z0-9_]+)(-\d{14})?\.csv(\.gz)?$/

      def self.args
        super.merge!(
          name:        ['--name=NAME',         'Dump file name (default to dump)'],
          base_dir:    ['--base-dir=BASE_DIR', 'Dump file(s) base directory (default to ENV["RAILS_ROOT"]/db)'],
          includes:    ['--includes=INCLUDES', 'Included tables'],
          excludes:    ['--excludes=EXCLUDES', 'Excluded tables (only for CSV)'],
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
        if options.includes.present?
          only = options.includes.split(',').reject(&:blank?).uniq
        end
        if options.excludes.present?
          skip = options.excludes.split(',').reject(&:blank?).uniq
        end
        tables = csv_files.each_with_object({}) do |file, tables|
          table, timestamp, compress = file.basename.to_s.match(CSV_MATCHER).captures
          (tables[table] ||= []) << { file: file, time: timestamp, gz: compress }
        end
        Parallel.each(tables.keys, in_threads: Parallel.processor_count) do |table|
          next if (only&.any? && only.exclude?(table)) || (skip&.any? && skip.include?(table))
          tables[table].sort_by{ |csv| csv[:time] }.each do |csv|
            if csv[:gz]
              psql "\\COPY #{table} FROM PROGRAM 'unpigz -c #{csv[:file]}' CSV"
            else
              psql "\\COPY #{table} FROM '#{csv[:file]}' CSV"
            end
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
