module Db
  module Pg
    class Base < ActiveTask::Base
      include ExtRake::Pg::Rescuable

      def self.args
        { db: ['--db=DB', 'DB type (ex.: --db=record would use Record::Base connection'] }
      end

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
        @pg_conf_dir ||= Pathname.new(psql!('SHOW data_directory', sudo: true))
      end

      def psql!(command, *sh_rest, **options)
        psql(command, *sh_rest, raise_on_exception: true, **options)
      end

      def psql(command, *sh_rest, raise_on_exception: false, sudo: false)
        cmd = Sh.psql command, (ExtRake.config.db_url unless sudo)
        cmd = [cmd].concat(sh_rest).compact.join(' ')
        stdout, stderr, _status = Open3.capture3(cmd)
        notify!(cmd, stderr) if raise_on_exception && notify?(stderr)
        stdout
      end
    end
  end
end
