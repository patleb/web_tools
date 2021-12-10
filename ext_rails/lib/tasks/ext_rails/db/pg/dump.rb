module Db
  module Pg
    class Dump < Base
      SPLIT_SCALE = Rails.env.vagrant? ? 'MB' : 'GB'
      SPLIT_SIZE = Setting[:backup_split_size]
      PIGZ_CORES = (cores = (Etc.nprocessors / 2.0).ceil) > 24 ? 24 : cores
      EXTENSIONS = /\.[\w.-]+$/
      VERSION    = /[a-f0-9]{7}/

      def self.args
        {
          name:       ['--name=NAME',                  'Dump file name (default to "dump")'],
          base_dir:   ['--base-dir=BASE_DIR',          'Dump file(s) base directory (default to Setting[:backup_dir])'],
          version:    ['--[no-]version',               'Add a git version number to the dump'],
          rotate:     ['--[no-]rotate',                'Rotate dumps (only for pg_dump)'],
          days:       ['--days=DAYS',         Integer, 'Number of days in rotation (default to 5, min 5, max 6)'],
          weeks:      ['--weeks=WEEKS',       Integer, 'Number of weeks in rotation (default to 3, min 1, max 3)'],
          months:     ['--months=MONTHS',     Integer, 'Number of months in rotation (default to 2, min 0)'],
          includes:   ['--includes=INCLUDES', Array,   'Included tables (only for pg_dump and COPY command)'],
          excludes:   ['--excludes=EXCLUDES', Array,   'Excluded tables (only for pg_dump and COPY command)'],
          compress:   ['--[no-]compress',              'Compress the dump (default to true)'],
          split:      ['--[no-]split',                 'Compress and split the dump'],
          md5:        ['--[no-]md5',                   'Generate md5 file after successful dump'],
          physical:   ['--[no-]physical',              'Use pg_basebackup instead of pg_dump'],
          wal:        ['--[no-]wal',                   'Use pg_receivewal with pg_basebackup (default to true)'],
          csv:        ['--[no-]csv',                   'Use COPY command instead of pg_dump'],
          where:      ['--where=WHERE',                'WHERE condition for the COPY command'],
          pg_options: ['--pg_options=PG_OPTIONS',      'Extra postgres options'],
        }
      end

      def self.defaults
        {
          name: 'dump',
          base_dir: Setting[:backup_dir],
          includes: [],
          excludes: [],
          compress: true,
          wal: true,
        }
      end

      def dump
        case
        when options.physical then pg_basebackup
        when options.csv      then copy_to
        else pg_dump
        end
      end

      private

      def pg_basebackup
        raise "dangerous dump_path: [#{dump_path}]" unless dump_path.to_s.squish_char('/').count('/') >= 2
        sh "sudo rm -f #{dump_path}/*"
        sh "sudo mkdir -p #{dump_path}", verbose: false
        sh "sudo chown -R postgres:postgres #{dump_path}", verbose: false
        sh "sudo chmod +r #{dump_path}", verbose: false
        pg_receivewal do
          output = case
            when options.split    then "-D- | #{split_cmd(tar_file)}"
            when options.compress then "-D- | #{compress_cmd(tar_file)}"
            else "-D #{dump_path}"
            end
          sh su_postgres "pg_basebackup -v -Xnone -cfast -Ft #{pg_options} #{output}"
        end
        manifest_path = dump_path.join("#{today}-#{MixServer.current_version}")
        sh "sudo cp /home/#{Setting[:owner_name]}/#{Sunzistrano::Context::MANIFEST_DIR}/postgresql.log #{manifest_path}"
      end

      def pg_receivewal
        if options.wal
          sh "sudo mkdir -p #{dump_wal_dir}", verbose: false
          sh "sudo chown postgres:postgres #{dump_wal_dir}", verbose: false
          psql! "SELECT * FROM pg_create_physical_replication_slot('#{slot_name}')"
          pid = spawn su_postgres "pg_receivewal --synchronous -S #{slot_name} -D #{dump_wal_dir}"
        end
        yield
      ensure
        if options.wal
          psql! "SELECT pg_switch_wal()"
          sh "sudo pkill pg_receivewal"
          Process.kill('TERM', pid)
          Process.detach(pid)
          sleep 1 while system("sudo pgrep pg_receivewal")
          psql! "SELECT * FROM pg_drop_replication_slot('#{slot_name}')"
          if compress
            sh su_postgres "tar cvf - -C #{dump_wal_dir} . | #{compress_cmd(wal_file)}"
          else
            sh su_postgres "tar -cvf #{wal_file} -C #{dump_wal_dir} ."
            sh "sudo md5sum #{wal_file} | sudo tee #{wal_file}.md5 > /dev/null" if options.md5
          end
          sh "sudo rm -rf #{dump_wal_dir}"
        end
      end

      def copy_to
        dump_path.dirname.mkpath
        where = "WHERE #{options.where}" if options.where.present?
        tables = (options.includes.reject(&:blank?) - options.excludes.reject(&:blank?)).uniq
        tables.each do |table|
          file = csv_file(table)
          output = case
            when options.split    then "PROGRAM '#{split_cmd(file)}'"
            when options.compress then "PROGRAM '#{compress_cmd(file)}'"
            else "'#{file}'"
            end
          psql! "\\COPY (SELECT * FROM #{table} #{where}) TO #{output} DELIMITER ',' CSV #{pg_options}"
        end
      end

      def pg_dump
        dump_path.dirname.mkpath
        if options.rotate && !rotation?
          puts_info 'DUMP', 'skipped: not in the rotation'
          return
        end
        Setting.db do |host, port, database, username, password|
          only = options.includes.reject(&:blank?)
          skip = options.excludes.reject(&:blank?)
          cmd_options = <<-CMD.squish
            --host #{host} --port #{port} --username #{username} --verbose --no-owner --no-acl --clean --format=c --compress=0
            #{pg_options}
            #{only.map{ |table| "--table='#{table}' --table='#{table}_id_seq'" }.join(' ')}
            #{skip.map{ |table| "--exclude-table='#{table}' --exclude-table='#{table}_id_seq'" }.join(' ')}
            #{database}
          CMD
          output = case
            when options.split    then "| #{split_cmd(pg_file)}"
            when options.compress then "| #{compress_cmd(pg_file)}"
            else pg_file
            end
          cmd = <<~CMD
            export PGPASSWORD=#{password};
            pg_dump #{cmd_options} #{output}
          CMD
          _stdout, stderr, _status = Open3.capture3(cmd)
          notify!(cmd, stderr) if notify?(stderr)
        end
        rotate_dump if options.rotate
      end

      def rotate_dump
        dump_dates = Pathname.new(dump_path.dirname).glob("#{options.name}_*").select_map do |path|
          path = path.basename.to_s.gsub(/(^#{options.name}_|-#{VERSION}|#{EXTENSIONS})/, '')
          path if path.match? /^\d{4}_\d{2}_\d{2}$/
        end.uniq
        (dump_dates - rotations).each do |date|
          dump_path.dirname.glob("#{options.name}_#{date}*").each(&:delete)
        end
        dump_versions = Pathname.new(dump_path.dirname).glob("#{options.name}_#{rotations.first}-*").select_map do |path|
          path unless path.basename.to_s.match? /-#{MixServer.current_version}#{EXTENSIONS}/
        end
        dump_versions.each(&:delete)
      end

      def split_cmd(file)
        if options.md5
          md5sum = %{echo $(md5sum | cut -d " " -f 1 | tr -d "\\n") " "$FILE > $FILE.md5}
          md5sum = %{tee >(#{md5sum}) > $FILE}
          md5sum = %{--filter="#{md5sum.gsub(/(["$])/, "\\\\\\1")}"}
        end
        "pigz -p #{PIGZ_CORES} | split -d -a 6 -b #{SPLIT_SIZE}#{SPLIT_SCALE} #{md5sum} - #{file}.gz-"
      end

      def compress_cmd(file)
        if options.md5
          md5sum = %{echo $(md5sum | cut -d " " -f 1 | tr -d "\\n") " "#{file}.gz > #{file}.gz.md5}
          md5sum = %{| tee >(#{md5sum})}
        end
        "pigz -p #{PIGZ_CORES} #{md5sum} > #{file}.gz"
      end

      def tar_file
        dump_path.join('base.tar')
      end

      def wal_file
        dump_path.join('pg_wal.tar')
      end

      def csv_file(table)
        dump_path.sub_ext("~#{table}.csv")
      end

      def pg_file
        dump_path.sub_ext('.pg')
      end

      def compress
        options.compress || options.split
      end

      def slot_name
        @slot_name ||= dump_path.to_s.full_underscore
      end

      def dump_wal_dir
        @dump_wal_dir ||= dump_path.sub_ext('-wal')
      end

      def dump_path
        @dump_path ||= Pathname.new(options.base_dir).join(dump_name).expand_path
      end

      def dump_name
        name = !options.physical && !options.csv && options.rotate ? "#{options.name}_#{rotations.first}" : options.name
        name = "#{name}-#{MixServer.current_version}" if !options.physical && options.version
        name
      end

      def rotation?
        rotations.first == today
      end

      def rotations
        @rotations ||= Time.current.rotations(days: options.days, weeks: options.weeks, months: options.months)
      end

      def today
        Time.current.beginning_of_day.to_date.to_s(:db).tr('-', '_')
      end
    end
  end
end
