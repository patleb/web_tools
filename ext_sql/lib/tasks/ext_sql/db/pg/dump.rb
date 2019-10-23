# https://www.cybertec-postgresql.com/en/tech-preview-improving-copy-and-bulkloading-in-postgresql-12/
module Db
  module Pg
    class Dump < Base
      def self.args
        super.merge!(
          name:      ['--name=NAME',         'Dump file name (default to dump)'],
          base_dir:  ['--base-dir=BASE_DIR', 'Dump file(s) base directory (default to ENV["RAILS_ROOT"]/db)'],
          includes:  ['--includes=INCLUDES', 'Included tables'],
          excludes:  ['--excludes=EXCLUDES', 'Excluded tables'],
          timestamp: ['--[no-]timestamp',    'Add a timestamp in the CSV file name'],
          csv:       ['--[no-]csv',          'Dump as CSV'],
          compress:  ['--[no-]compress',     'Specify if the resulting CSV is compressed (default to true)'],
          where:     ['--where=WHERE',       'WHERE condition for the COPY command']
        )
      end

      def self.defaults
        {
          name: 'dump',
          includes: '',
          excludes: '',
          base_dir: ExtRake.config.rails_root.join('db'),
          compress: true,
        }
      end

      def dump
        options.csv ? copy_to : pg_dump
      end

      private

      def copy_to
        dump_path.mkpath
        where = "WHERE #{options.where}" if options.where.present?
        tables = (options.includes.split(',').reject(&:blank?) - options.excludes.split(',').reject(&:blank?)).uniq
        tables.each do |table|
          file = csv_file(table)
          if options.compress
            psql "\\COPY (SELECT * FROM #{table} #{where}) TO PROGRAM 'pigz > #{file}' DELIMITER ',' CSV"
          else
            psql "\\COPY (SELECT * FROM #{table} #{where}) TO '#{file}' DELIMITER ',' CSV"
          end
        end
      end

      def pg_dump
        if options.includes.present?
          only = options.includes.split(',').reject(&:blank?)
        end
        if options.excludes.present?
          skip = options.excludes.split(',').reject(&:blank?)
        end
        (skip ||= []) << ActiveRecord::Base.internal_metadata_table_name
        with_config do |host, db, user, pwd|
          cmd_options = <<~CMD.squish
            --host #{host}
            --username #{user}
            #{self.class.pg_options}
            --verbose
            --no-owner
            --no-acl
            --clean
            --format=c
            #{only.map{ |table| "--table='#{table}'" }.join(' ')}
            #{skip.map{ |table| "--exclude-table='#{table}'" }.join(' ')}
            #{db}
          CMD
          sh <<~CMD, verbose: false
            export PGPASSWORD=#{pwd};
            pg_dump #{cmd_options} > #{pg_file}
          CMD
        end
      end

      def csv_file(table)
        if options.timestamp
          loop do
            file = dump_path.join(table).sub_ext("-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}.csv#{'.gz' if options.compress}")
            break file unless file.exist?
            spleep 1
          end
        else
          dump_path.join(table).sub_ext(".csv#{'.gz' if options.compress}")
        end
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
