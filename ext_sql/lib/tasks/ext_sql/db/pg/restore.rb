# TODO parallelize
# https://github.com/timescale/timescaledb-parallel-copy
# http://www.programmersought.com/article/8849706613/
# https://www.citusdata.com/blog/2016/06/15/copy-postgresql-distributed-tables
# https://citusdata.com/blog/2017/11/08/faster-bulk-loading-in-postgresql-with-copy/
# http://www.programmersought.com/article/8849706613/
# https://stackoverflow.com/questions/14980048/how-to-decompress-with-pigz
module Db
  module Pg
    class Restore < Base
      class MismatchedExtension < ::StandardError; end

      TABLE = /~[A-Za-z_][A-Za-z0-9_]*/
      COMPRESS = /\.gz/
      SPLIT = /-\*/
      MATCHER = /(#{TABLE})?\.(tar|csv|pg)(#{COMPRESS})?(#{SPLIT})?$/

      def self.args
        {
          name:        ['--name=NAME',                'Dump file name', :required],
          base_dir:    ['--base-dir=BASE_DIR',        'Dump file(s) base directory (default to ENV["RAILS_ROOT"]/db)'],
          includes:    ['--includes=INCLUDES', Array, 'Included tables for pg_restore'],
          staged:      ['--[no-]staged',              'Force restore in 3 phases for pg_restore (pre-data, data, post-data)'],
          timescaledb: ['--[no-]timescaledb',         'Specify if TimescaleDB is used for pg_restore'],
        }
      end

      def self.defaults
        {
          base_dir: ExtRake.config.rails_root.join('db'),
          includes: [],
        }
      end

      def restore
        table, type, compress, split = dump_path.basename.to_s.match(MATCHER).captures
        case type
        when 'tar' then unpack(compress, split)
        when 'csv' then copy_from(table, compress, split)
        when 'pg'  then pg_restore(compress, split)
        else raise MismatchedExtension, type
        end
      end

      private

      def unpack(compress, split)
        data_dir = pg_conf_dir
        sh 'sudo systemctl stop postgresql'
        sh "sudo rm -rf #{data_dir}"
        sh "sudo mkdir -p #{data_dir}"
        input = case
          when split    then "#{unsplit_cmd} |"
          when compress then "#{uncompress_cmd} |"
          else nil
          end
        sh "sudo bash -c '#{input} tar -xvf #{input ? '-' : dump_path} -C #{data_dir}'"
        sh "sudo bash -c 'chown -R postgres:postgres #{data_dir}'"
        sh 'sudo systemctl start postgresql'
      end

      def copy_from(table, compress, split)
        input = case
          when split    then "PROGRAM '#{unsplit_cmd}'"
          when compress then "PROGRAM '#{uncompress_cmd}'"
          else "'#{dump_path}'"
          end
        psql! "\\COPY #{table} FROM #{input} CSV"
      end

      def pg_restore(compress, split)
        only = options.includes.reject(&:blank?)
        with_db_config do |host, db, user, pwd|
          cmd_options = <<~CMD.squish
            --host #{host} --username #{user} --verbose --no-owner --no-acl
            #{self.class.pg_options}
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
          sections.each do |section|
            cmd = <<~CMD
              export PGPASSWORD=#{pwd};
              #{input} pg_restore #{cmd_options} #{"--section=#{section}" if section} #{dump_path if input.nil?}
            CMD
            _stdout, stderr, _status = Open3.capture3(cmd)
            notify!(cmd, stderr) if notify?(stderr)
          end
          post_restore_timescaledb if options.timescaledb
        end
      end

      def pre_restore_timescaledb
        psql! <<-SQL.strip_sql
          CREATE EXTENSION IF NOT EXISTS timescaledb;
          SELECT timescaledb_pre_restore();
        SQL
      end

      def post_restore_timescaledb
        psql! <<-SQL.strip_sql
          SELECT timescaledb_post_restore();
        SQL
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

      def dump_path
        @dump_path ||= Pathname.new(options.base_dir).join(options.name).expand_path
      end
    end
  end
end
