module Db
  module Pg
    class Base < ActiveTask::Base
      include ExtRake::Pg::Psql
      include ExtRake::Pg::Rescuable

      def self.pg_options
        ENV['PG_OPTIONS']
      end

      def sh(*cmd, &block)
        pg_conf_dir
        super
      end

      protected

      def with_db_config
        db = ExtRake.config.db_config
        yield db[:host],
          db[:database],
          db[:username],
          db[:password]
      end

      def pg_conf_dir
        @pg_conf_dir ||= begin
          data_dir = Pathname.new(psql! 'SHOW data_directory', sudo: true)
          `echo #{data_dir} > tmp/pg_conf_dir`
          data_dir
        rescue
          Pathname.new(Pathname.new('tmp/pg_conf_dir').read.strip)
        end
      end

      def su_postgres(cmd)
        <<-CMD.squish
          cd /tmp && sudo su postgres -c 'set -e; #{cmd}'
        CMD
      end
    end
  end
end
