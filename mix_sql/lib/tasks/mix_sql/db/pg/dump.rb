module Db
  module Pg
    class Dump < Base
      SPLIT_SCALE = Rails.env.vagrant? ? 'MB' : 'GB'
      SPLIT_SIZE = 2
      # PIGZ_CORES = (Etc.nprocessors - 2) > 0 ? Etc.nprocessors - 2 : 1
      PIGZ_CORES = (Etc.nprocessors / 2.0).ceil

      def self.args
        {
          name:     ['--name=NAME',                'Dump file name (default to dump)'],
          base_dir: ['--base-dir=BASE_DIR',        'Dump file(s) base directory (default to ENV["RAILS_ROOT"]/db)'],
          includes: ['--includes=INCLUDES', Array, 'Included tables (only for pg_dump and COPY command)'],
          excludes: ['--excludes=EXCLUDES', Array, 'Excluded tables (only for pg_dump and COPY command)'],
          compress: ['--[no-]compress',            'Compress the dump (default to true)'],
          split:    ['--[no-]split',               'Compress and split the dump'],
          md5:      ['--[no-]md5',                 'Generate md5 file after successful dump'],
          physical: ['--[no-]physical',            'Use pg_basebackup instead of pg_dump'],
          wal:      ['--[no-]wal',                 'Use pg_receivewal with pg_basebackup (default to true)'],
          csv:      ['--[no-]csv',                 'Use COPY command instead of pg_dump'],
          where:    ['--where=WHERE',              'WHERE condition for the COPY command'],
        }
      end

      def self.defaults
        {
          name: 'dump',
          base_dir: ExtRake.config.rails_root.join('db'),
          includes: [],
          excludes: [],
          compress: true,
          wal: true,
        }
      end

      def dump
        sh "sudo chmod +r #{dump_path}", verbose: false
        case
        when options.physical then pg_basebackup
        when options.csv      then copy_to
        else pg_dump
        end
      end

      private

      # TODO add postgres page checksum --> https://postgreshelp.com/postgresql-checksum/
      def pg_basebackup
        pg_receivewal do
          sh "sudo mkdir -p #{dump_path.dirname}"
          sh "sudo chown postgres:postgres #{dump_path.dirname}"
          output = case
            when options.split    then "-D- | #{split_cmd(tar_file)}"
            when options.compress then "-D- | #{compress_cmd(tar_file)}"
            else "-D #{dump_path}"
            end
          sh su_postgres "pg_basebackup -v -Xnone -cfast -Ft #{self.class.pg_options} #{output}"
        end
      end

      def pg_receivewal
        if options.wal
          sh "sudo mkdir -p #{dump_wal_dir}"
          sh "sudo chown postgres:postgres #{dump_wal_dir}"
          sh "sudo rm -f #{dump_wal_dir}/*"
          psql! "SELECT * FROM pg_create_physical_replication_slot('#{options.name}')"
          pid = spawn su_postgres "pg_receivewal --synchronous -S #{options.name} -D #{dump_wal_dir}"
        end
        yield
      ensure
        if options.wal
          psql! "SELECT pg_switch_wal()"
          sh "sudo pkill pg_receivewal"
          Process.kill('TERM', pid)
          Process.detach(pid)
          sleep 1 while system("sudo pgrep pg_receivewal")
          psql! "SELECT * FROM pg_drop_replication_slot('#{options.name}')"
          if compress
            sh su_postgres "tar cvf - -C #{dump_wal_dir} . | #{compress_cmd(wal_file)}"
          else
            sh su_postgres "tar -cvf #{wal_file} -C #{dump_wal_dir} ."
            sh "sudo md5sum #{wal_file} | sudo tee #{wal_file}.md5 > /dev/null" if options.md5
          end
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
          psql! "\\COPY (SELECT * FROM #{table} #{where}) TO #{output} DELIMITER ',' CSV #{self.class.pg_options}"
        end
      end

      def pg_dump
        only = options.includes.reject(&:blank?)
        skip = options.excludes.reject(&:blank?)
        skip << ActiveRecord::Base.internal_metadata_table_name
        with_db_config do |host, db, user, pwd|
          cmd_options = <<-CMD.squish
            --host #{host} --username #{user} --verbose --no-owner --no-acl --clean --format=c --compress=0
            #{self.class.pg_options}
            #{only.map{ |table| "--table='#{table}'" }.join(' ')}
            #{skip.map{ |table| "--exclude-table='#{table}'" }.join(' ')}
            #{db}
          CMD
          output = case
            when options.split    then "| #{split_cmd(pg_file)}"
            when options.compress then "| #{compress_cmd(pg_file)}"
            else pg_file
            end
          sh <<~CMD, verbose: false
            export PGPASSWORD=#{pwd};
            pg_dump #{cmd_options} #{output}
          CMD
        end
      end

      def split_cmd(file)
        if options.md5
          md5sum = %{tee >(md5sum | cut -d " " -f 1 | tr -d "\\n" > $FILE.md5 && echo " "" $FILE" >> $FILE.md5) > $FILE}
          md5sum = %{--filter="#{md5sum.gsub(/(["$])/, "\\\\\\1")}"}
        end
        "pigz -p #{PIGZ_CORES} | split -a 4 -b #{SPLIT_SIZE}#{SPLIT_SCALE} #{md5sum} - #{file}.gz-"
      end

      def compress_cmd(file)
        if options.md5
          md5sum = %{| tee >(md5sum | cut -d " " -f 1 | tr -d "\\n" > #{file}.gz.md5 && echo " "" #{file}.gz" >> #{file}.gz.md5)}
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

      def dump_wal_dir
        @dump_wal_dir ||= dump_path.sub_ext('_wal')
      end

      def dump_path
        @dump_path ||= Pathname.new(options.base_dir).join(options.name).expand_path
      end
    end
  end
end
