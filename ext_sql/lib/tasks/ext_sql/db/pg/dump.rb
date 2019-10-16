# https://www.cybertec-postgresql.com/en/tech-preview-improving-copy-and-bulkloading-in-postgresql-12/
module Db
  module Pg
    class Dump < Base
      def self.args
        super.merge!(
          name:     ['--name=NAME',         'Dump name (default to dump)'],
          base_dir: ['--base-dir=BASE_DIR', 'Dump file base directory (default to ENV["RAILS_ROOT"]/db(/dump for CSV))'],
          includes: ['--includes=INCLUDES', 'Included tables'],
          excludes: ['--excludes=EXCLUDES', 'Excluded tables'],
          csv:      ['--[no-]csv',          'Dump as CSV'],
          compress: ['--[no-]compress',     'Specify if the resulting CSV is compressed (default to true)'],
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
        if options.csv
          copy_to
        else
          pg_dump
        end
      end

      private

      def copy_to
        dump_dir = Pathname.new(options.base_dir).join(options.name)
        dump_dir.mkpath
        tables = (options.includes.split(',').reject(&:blank?) - options.excludes.split(',').reject(&:blank?)).uniq
        tables.each do |table|
          file = dump_file(dump_dir, table)
          if options.compress
            psql "\\COPY (SELECT * FROM #{table}) TO PROGRAM 'pigz > #{file}' DELIMITER ',' CSV"
          else
            psql "\\COPY (SELECT * FROM #{table}) TO '#{file}' DELIMITER ',' CSV"
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
            pg_dump #{cmd_options} > #{options.base_dir}/#{options.name}.pg
          CMD
        end
      end

      def dump_file(dump_dir, table)
        "#{dump_dir.join(table)}.csv#{'.gz' if options.compress}"
      end
    end
  end
end
