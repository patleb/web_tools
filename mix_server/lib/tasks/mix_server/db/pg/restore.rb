# frozen_string_literal: true

module Db
  module Pg
    class Restore < Base
      class MismatchedExtension < ::StandardError; end

      TABLE = /[A-Za-z_]\w*/
      COMPRESS = /\.gz/
      SPLIT = /-\*/
      MATCHER = /(?:~(#{TABLE}))?\.(tar|csv|pg)(#{COMPRESS})?(#{SPLIT})?$/
      PARTITION = /\d{4}_\d{2}_\d{2}|\d{19}/

      def self.args
        {
          path:       ['--path=PATH',                'Dump path', :required],
          includes:   ['--includes=INCLUDES', Array, 'Included tables for pg_restore'],
          excludes:   ['--excludes=EXCLUDES', Array, 'Excluded tables for pg_restore'],
          md5:        ['--[no-]md5',                 'Check md5 files if present (default to true)'],
          staged:     ['--[no-]staged',              'Force restore in 3 phases for pg_restore (pre-data, data, post-data)'],
          data_only:  ['--[no-]data-only',           'Load only data with disabled triggers for pg_restore'],
          append:     ['--[no-]append',              'Append data for pg_restore'],
          pg_options: ['--pg_options=PG_OPTIONS',    'Extra options passed to pg_restore'],
          new_server: ['--[no-]new-server',          'Reset current server centralized log'],
        }
      end

      def self.defaults
        {
          includes: [],
          excludes: [],
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
          started_at = Concurrent.monotonic_time
          sh "sudo find #{dump_path} -type f -name '*.md5' | sudo parallel --no-notice 'md5sum -c {} > /dev/null'"
          puts_info 'MD5', 'checked', started_at: started_at
        end
      end

      def unpack(compress, split)
        sh 'sudo systemctl stop postgresql'
        sh "sudo rm -rf #{pg_data_dir}"
        sh "sudo mkdir -p #{pg_data_dir}"
        started_at = Concurrent.monotonic_time
        if split
          list_cmd = "find #{dump_path.dirname} -iname #{dump_path.basename} -not -name *.md5"
          sh "sudo bash -c '#{list_cmd} | sort | xargs cat | tar -C #{pg_data_dir} #{'-I pigz' if compress} -xf -'"
        else
          sh "sudo bash -c 'tar -C #{pg_data_dir} #{'-I pigz' if compress} -xf #{dump_path}'"
        end
        puts_info 'UNPACK', 'finished', started_at: started_at
        if system("sudo ls #{wal_file(compress)}", out: File::NULL, err: File::NULL)
          sh "sudo tar -C #{wal_dir} #{'-I pigz' if compress} -xf #{wal_file(compress)}"
          if system("sudo ls #{wal_dir}/*.partial", out: File::NULL, err: File::NULL)
            sh "sudo mmv '#{wal_dir}/*.partial' '#{wal_dir}/#1'"
          end
        end
        sh "sudo touch #{pg_data_dir.join('recovery.signal')}"
        sh "sudo chmod 700 #{pg_data_dir}"
        sh "sudo chown -R postgres:postgres #{pg_data_dir}"
        sh 'sudo systemctl start postgresql'
        Db::Pg::Truncate.new(rake, task, cascade: true, includes: ExtRails.config.temporary_tables.to_a).run!
        post_restore_environment
      end

      def copy_from(table, compress, split)
        input = case
          when split    then "PROGRAM '#{unsplit_uncompress_cmd}'"
          when compress then "PROGRAM '#{uncompress_cmd}'"
          else "'#{dump_path}'"
          end
        psql! "\\COPY #{table} FROM #{input} CSV"
      end

      def pg_restore(compress, split)
        Setting.db do |host, port, database, username, password|
          output = ''
          only = options.includes.reject(&:blank?)
          skip = options.excludes.reject(&:blank?)
          sections = staged ? %w(list pre-data data post-data) : ['list', false]
          sections.each do |section|
            section = case section
              when false  then nil
              when 'list' then '--list'
              else "--section=#{section}"
              end
            cmd_options = <<~CMD.squish
              --host #{host} --port #{port} --username #{username} --verbose --no-owner --no-acl
              #{'--disable-triggers --data-only' if options.data_only}
              #{pg_options}
              #{only.map{ |table| "--table='#{table}'" }.join(' ') unless section == '--list'}
              --dbname #{database}
            CMD
            input = case
              when split    then "#{unsplit_uncompress_cmd} |"
              when compress then "#{uncompress_cmd} |"
              else nil
              end
            cmd = <<~CMD
              export PGPASSWORD=#{password};
              #{input} pg_restore #{cmd_options} #{section} #{dump_path if input.nil?}
            CMD
            stdout, stderr, _status = Open3.capture3(cmd)
            if section == '--list'
              notify!(cmd, stderr) if notify?(stderr)
              pre_restore_schema(stdout, only, skip)
            else
              output << stdout
              notify!(cmd, stderr) if notify?(stderr)
            end
          end
          post_restore_environment unless data_append?
          output
        end
      end

      def pre_restore_schema(output, only, skip)
        tables = output.lines.select_map{ |line| line.match(/TABLE public (#{TABLE}) /)&.captures&.first }
        if only.any?
          tables.select! do |t|
            only.any?{ |t_only| t.match_glob? t_only }
          end
          only.replace(intersperse_with_sequences(tables)) unless skip.any?
        end
        if skip.any?
          tables.reject! do |t|
            skip.any?{ |t_skip| t.match_glob? t_skip }
          end
          only.replace(intersperse_with_sequences(tables))
        end
        return unless options.data_only

        tables = Set.new(tables)
        data_tables = output.lines.select_map do |line|
          next unless (table = line.match(/TABLE DATA public (#{TABLE}) /)&.captures&.first)
          table if tables.include? table
        end
        unless data_append?
          Db::Pg::Truncate.new(rake, task, isolate: true, cascade: true, includes: data_tables).run!
        end

        partitions = output.lines.each_with_object({}) do |line, list|
          next unless (table, bucket = line.match(/TABLE public (#{TABLE})_(#{PARTITION}) /)&.captures)
          next unless tables.include? table
          (list[table] ||= []) << bucket
        end
        partitions.each do |table, buckets|
          buckets.sort.each_with_index do |key, i|
            if (next_key = buckets[i + 1])
              ActiveRecord::Base.create_partition(table: table, from: key, to: next_key)
            else
              ActiveRecord::Base.create_partition(key, table: table)
            end
          end
        end
      end

      def post_restore_environment
        ActiveRecord::Base.connection.internal_metadata[:environment] = Rails.env
        Server.current.discard! if options.new_server && !Server.current.new?
      end

      def staged
        options.staged
      end

      def unsplit_uncompress_cmd
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
        @dump_path ||= Pathname.new(options.path).expand_path
      end

      def data_append?
        options.data_only && options.append
      end

      def intersperse_with_sequences(tables)
        tables.flat_map{ |table| table.match?(/#{TABLE}_#{PARTITION}/) ? table :  [table, "#{table}_id_seq"] }
      end
    end
  end
end
