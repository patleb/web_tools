module Db
  module Pg
    class Dump < Base
      def self.steps
        [:pg_dump]
      end

      def self.args
        super.merge!(
          name:     ['--name=NAME',         'Dump name (default to dump)'],
          includes: ['--includes=INCLUDES', 'Included tables'],
          excludes: ['--excludes=EXCLUDES', 'Excluded tables'],
        )
      end

      # TODO clear ar_internal_metadata --> rake task already exists?
      def pg_dump
        with_config do |host, db, user, pwd|
          if options.includes.present?
            only = options.includes.split(',').reject(&:blank?).map{ |table| "--table='#{table}'" }.join(' ')
          end
          if options.excludes.present?
            skip = options.excludes.split(',').reject(&:blank?).map{ |table| "--exclude-table='#{table}'" }.join(' ')
          end
          name = options.name.presence || 'dump'
          cmd_options = <<~CMD.squish
            --host #{host}
            --username #{user}
            #{self.class.pg_options}
            --verbose
            --no-owner
            --no-acl
            --clean
            --format=c
            #{only}
            #{skip}
            #{db}
          CMD
          sh <<~CMD, verbose: false
            export PGPASSWORD=#{pwd};
            pg_dump #{cmd_options} > #{ExtRake.config.rails_root}/db/#{name}.pg
          CMD
        end
      end
    end
  end
end
