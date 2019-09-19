module Db
  module Pg
    class Restore < Base
      def self.steps
        [:pg_restore]
      end

      def self.args
        super.merge!(
          name:        ['--name=NAME',         'Dump name (default to dump)'],
          includes:    ['--includes=INCLUDES', 'Included tables'],
          staged:      ['--[no-]staged',       'Force restore in 3 phases (pre-data, data, post-data)'],
          timescaledb: ['--[no-]timescaledb',  'Specify if TimescaleDB is used'],
        )
      end

      # TODO adapt for single tables --> https://docs.timescale.com/latest/using-timescaledb/backup#pg_dump-pg_restore
      def pg_restore
        with_config do |host, db, user, pwd|
          if options.includes.present?
            only = options.includes.split(',').reject(&:blank?).map{ |table| "--table='#{table}'" }.join(' ')
          end
          name = options.name.presence || 'dump'
          cmd_options = <<~CMD.squish
            --verbose
            --host #{host}
            --username #{user}
            #{self.class.pg_options}
            --no-owner
            --no-acl
            #{only}
            --dbname #{db}
          CMD
          pre_restore_timescaledb if options.timescaledb
          sections = staged ? %w(pre-data data post-data) : [nil]
          sections.each do |section|
            cmd = <<~CMD
              export PGPASSWORD=#{pwd};
              pg_restore #{cmd_options} #{"--section=#{section}" if section} #{ExtRake.config.rails_root}/db/#{name}.pg
            CMD
            _stdout, stderr, _status = Open3.capture3(cmd)
            notify!(cmd, stderr) if notify?(stderr)
          end
          post_restore_timescaledb if options.timescaledb
        end
      end

      private

      def pre_restore_timescaledb
        psql(<<-SQL.strip_sql)
          CREATE EXTENSION timescaledb;
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
    end
  end
end
