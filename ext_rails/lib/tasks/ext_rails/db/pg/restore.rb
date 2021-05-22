module Db
  module Pg
    class Restore < Base
      class MismatchedExtension < ::StandardError; end

      TABLE = /[A-Za-z_][A-Za-z0-9_]*/
      COMPRESS = /\.gz/
      SPLIT = /-\*/
      MATCHER = /(?:~(#{TABLE}))?\.(tar|csv|pg)(#{COMPRESS})?(#{SPLIT})?$/
      PARTITION = /TABLE public (#{TABLE})_(\d{4}_\d{2}_\d{2}|\d{10}) /

      def self.args
        {
          name:        ['--name=NAME',                'Dump file name', :required],
          base_dir:    ['--base-dir=BASE_DIR',        'Dump file(s) base directory (default to ENV["RAILS_ROOT"]/db)'],
          includes:    ['--includes=INCLUDES', Array, 'Included tables for pg_restore'],
          md5:         ['--[no-]md5',                 'Check md5 files if present (default to true)'],
          staged:      ['--[no-]staged',              'Force restore in 3 phases for pg_restore (pre-data, data, post-data)'],
          data_only:   ['--[no-]data-only',           'Load only data with disabled triggers for pg_restore'],
          data_size:   ['--data-size=DATA_SIZE',      'Specify the partition size (used with :data_only option)'],
          timescaledb: ['--[no-]timescaledb',         'Specify if TimescaleDB is used for pg_restore'],
          pgrest:      ['--[no-]pgrest',              'Specify if PostgREST API is used for pg_restore'],
          pg_options:  ['--pg_options=PG_OPTIONS',    'Extra options passed to pg_restore'],
        }
      end

      def self.defaults
        {
          base_dir: MixTask.config.rails_root.join('db'),
          includes: [],
          md5: true,
        }
      end

      def restore
        check_md5 if options.md5
        table, type, compress, split = dump_path.basename.to_s.match(MATCHER).captures
        case type
        when 'tar' then unpack(compress, split)
        when 'csv' then copy_from(table, compress, split)
        when 'pg'  then pg_restore(compress, split)
        else raise MismatchedExtension, type
        end
      end

      private

      def check_md5
        md5_files = dump_path.sub(MATCHER, '*.md5')
        if system("sudo ls #{md5_files}", out: File::NULL, err: File::NULL)
          sh "sudo find #{dump_path} -type f -name '*.md5' | sudo parallel --no-notice 'md5sum -c {} > /dev/null'"
          puts_info 'MD5', 'checked'
        end
      end

      # TODO PITR --> https://www.scalingpostgres.com/tutorials/postgresql-backup-point-in-time-recovery/
      def unpack(compress, split)
        sh 'sudo systemctl stop postgresql'
        sh "sudo rm -rf #{pg_data_dir}"
        sh "sudo mkdir -p #{pg_data_dir}"
        if split
          list_cmd = "find #{dump_path.dirname} -iname #{dump_path.basename} -not -name *.md5"
          sh "sudo bash -c '#{list_cmd} | sort | xargs cat | tar -C #{pg_data_dir} #{'-I pigz' if compress} -xf -'"
        else
          sh "sudo bash -c 'tar -C #{pg_data_dir} #{'-I pigz' if compress} -xf #{dump_path}'"
        end
        if system("sudo ls #{wal_file(compress)}", out: File::NULL, err: File::NULL)
          sh "sudo tar -C #{wal_dir} #{'-I pigz' if compress} -xf #{wal_file(compress)}"
          if system("sudo ls #{wal_dir}/*.partial", out: File::NULL, err: File::NULL)
            sh "sudo mmv '#{wal_dir}/*.partial' '#{wal_dir}/#1'"
          end
        end
        sh %{echo "restore_command = ':'" | sudo tee #{pg_data_dir.join('recovery.conf')} > /dev/null}
        sh "sudo chmod 700 #{pg_data_dir}"
        sh "sudo chown -R postgres:postgres #{pg_data_dir}"
        sh 'sudo systemctl start postgresql'
      end

      # TODO https://ossc-db.github.io/pg_bulkload/index.html
      def copy_from(table, compress, split)
        if options.timescaledb
          # TODO parallelize
          # https://github.com/timescale/timescaledb-parallel-copy
          # http://www.programmersought.com/article/8849706613/
          # https://www.citusdata.com/blog/2016/06/15/copy-postgresql-distributed-tables
          # https://citusdata.com/blog/2017/11/08/faster-bulk-loading-in-postgresql-with-copy/
          # http://www.programmersought.com/article/8849706613/
          # https://stackoverflow.com/questions/14980048/how-to-decompress-with-pigz
        else
          input = case
            when split    then "PROGRAM '#{unsplit_cmd}'"
            when compress then "PROGRAM '#{uncompress_cmd}'"
            else "'#{dump_path}'"
            end
          psql! "\\COPY #{table} FROM #{input} CSV"
        end
      end

      def pg_restore(compress, split)
        output = ''
        only = options.includes.reject(&:blank?)
        with_db_config do |host, db, user, pwd|
          cmd_options = <<~CMD.squish
            --host #{host} --username #{user} --verbose --no-owner --no-acl
            #{'--disable-triggers --data-only' if options.data_only}
            #{pg_options}
            #{only.map{ |table| "--table='#{table}'" }.join(' ')}
            --dbname #{db}
          CMD
          input = case
            when split    then "#{unsplit_cmd} |"
            when compress then "#{uncompress_cmd} |"
            else nil
            end
          pre_restore_timescaledb if options.timescaledb
          sections = staged ? %w(pre-data data post-data) : [false]
          sections.unshift('list') if options.data_only
          sections.each do |section|
            section = case section
              when false  then nil
              when 'list' then '--list'
              else "--section=#{section}"
              end
            cmd = <<~CMD
              export PGPASSWORD=#{pwd};
              #{input} pg_restore #{cmd_options} #{section} #{dump_path if input.nil?}
            CMD
            stdout, stderr, _status = Open3.capture3(cmd)
            if section == '--list'
              notify!(cmd, stderr) if notify?(stderr)
              list_restore(stdout, only)
            else
              output << stdout
              notify!(cmd, stderr) if notify?(stderr)
            end
          end
          post_restore_environment
          post_restore_timescaledb if options.timescaledb
          post_restore_pgrest if options.pgrest
          output
        end
      end

      def list_restore(output, only)
        partitions = output.lines.select_map{ |line| line.match(PARTITION)&.captures }
        partitions = partitions.each_with_object({}) do |(table, bucket), list|
          next if only.any? && only.exclude?(table)
          (list[table] ||= []) << ActiveRecord::Base.partition_bucket(bucket)
        end
        partitions.each do |table, buckets|
          ActiveRecord::Base.create_all_partitions(buckets, table, size: options.data_size.presence)
        end
      end

      def pre_restore_timescaledb
        psql! <<-SQL.strip_sql
          CREATE EXTENSION IF NOT EXISTS timescaledb;
          SELECT timescaledb_pre_restore();
        SQL
      end

      def post_restore_environment
        psql! <<-SQL.strip_sql
          UPDATE #{ActiveRecord::Base.internal_metadata_table_name} SET value = '#{Rails.env}' WHERE key = 'environment'
        SQL
      end

      def post_restore_timescaledb
        psql! <<-SQL.strip_sql
          SELECT timescaledb_post_restore();
        SQL
      end

      def post_restore_pgrest
        psql! <<-SQL.strip_sql
          DELETE FROM #{ActiveRecord::Base.schema_migrations_table_name} WHERE version = '20010000000820'
        SQL
        run_task 'db:migrate'
      end

      def staged
        options.staged || options.timescaledb
      end

      def unsplit_cmd
        "cat #{dump_path} | unpigz -c"
      end

      def uncompress_cmd
        "unpigz -c #{dump_path}"
      end

      def wal_file(compress)
        compress ? dump_path.dirname.join('pg_wal.tar.gz') : dump_path.dirname.join('pg_wal.tar')
      end

      def wal_dir
        @wal_dir ||= pg_data_dir.join('pg_wal')
      end

      def dump_path
        @dump_path ||= Pathname.new(options.base_dir).join(options.name).expand_path
      end
    end
  end
end
