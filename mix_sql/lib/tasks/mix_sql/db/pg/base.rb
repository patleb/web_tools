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
          data_dir = psql!('SHOW data_directory', sudo: true).presence || _pg_conf_dir
          `echo #{data_dir} > tmp/pg_conf_dir` if data_dir.present?
          Pathname.new(data_dir)
        rescue
          Pathname.new(_pg_conf_dir)
        end
      end

      def _pg_conf_dir
        Pathname.new('tmp/pg_conf_dir').read.strip
      end

      def su_postgres(cmd)
        <<-CMD.squish
          cd /tmp && sudo su postgres -c 'set -e; #{cmd}'
        CMD
      end
    end
  end
end
