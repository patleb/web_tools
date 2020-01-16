module ExtRake
  module Pg
    module Psql
      def psql!(command, *sh_rest, **options)
        psql(command, *sh_rest, raise_on_exception: true, **options)
      end

      def psql(command, *sh_rest, raise_on_exception: false, sudo: false)
        cmd = Sh.psql command, (ExtRake.config.db_url unless sudo)
        cmd = [cmd, *sh_rest].join(' ')
        stdout, stderr, _status = Open3.capture3(cmd)
        notify!(cmd, stderr) if raise_on_exception && notify?(stderr)
        stdout.strip
      end
    end
  end
end
