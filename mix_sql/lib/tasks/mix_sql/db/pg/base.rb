module Db
  module Pg
    class Base < ActiveTask::Base
      include ExtRake::Pg::Psql
      include ExtRake::Pg::Rescuable

      def self.pg_options
        ENV['PG_OPTIONS']
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
        @pg_conf_dir ||= Pathname.new(psql! 'SHOW data_directory', sudo: true)
      end
    end
  end
end
