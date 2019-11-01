# TODO wal backup
# https://www.cybertec-postgresql.com/en/tech-preview-improving-copy-and-bulkloading-in-postgresql-12/
# https://www.scalingpostgres.com/tutorials/postgresql-backup-point-in-time-recovery/
module Db
  module Pg
    class Dump < Base
      def self.args
        super.merge!(
          name:      ['--name=NAME',                'Dump file name (default to dump)'],
          base_dir:  ['--base-dir=BASE_DIR',        'Dump file(s) base directory (default to ENV["RAILS_ROOT"]/db)'],
          includes:  ['--includes=INCLUDES', Array, 'Included tables (only for pg_dump and COPY command)'],
          excludes:  ['--excludes=EXCLUDES', Array, 'Excluded tables (only for pg_dump and COPY command)'],
          compress:  ['--[no-]compress',            'Compress the dump (default to true)'],
          split:     ['--[no-]split',               'Compress and split the dump (default to false)'],
          physical:  ['--[no-]physical',            'Use pg_basebackup instead of pg_dump'],
          csv:       ['--[no-]csv',                 'Use COPY command instead of pg_dump'],
          where:     ['--where=WHERE',              'WHERE condition for the COPY command'],
        )
      end

      def self.defaults
        {
          name: 'dump',
          base_dir: ExtRake.config.rails_root.join('db'),
          includes: [],
          excludes: [],
          compress: true,
        }
      end

      # TODO https://www.tecmint.com/generate-verify-check-files-md5-checksum-linux/
      def dump
        case
        when options.physical then pg_basebackup
        when options.csv      then copy_to
        else pg_dump
        end
      end

      private

      def pg_basebackup
        output = case
          when options.split    then split_cmd(tar_file)
          when options.compress then compress_cmd(tar_file)
          else tar_file
          end
        sh "sudo su postgres -c 'mkdir -p #{dump_path.dirname}'"
        sh <<-CMD.squish, verbose: false
          sudo su postgres -c 'pg_basebackup #{self.class.pg_options} -P -v -R -Xstream -cfast -Z0 -Ft -D- | #{output}'
        CMD
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
        "pigz | split -a 4 -b 2GB - #{file}.gz-"
      end

      def compress_cmd(file)
        "pigz > #{file}.gz"
      end

      def tar_file
        dump_path.sub_ext('.tar')
      end

      def csv_file(table)
        dump_path.sub_ext("~#{table}.csv")
      end

      def pg_file
        dump_path.sub_ext('.pg')
      end

      def dump_path
        @dump_path ||= Pathname.new(options.base_dir).join(options.name).expand_path
      end
    end
  end
end
