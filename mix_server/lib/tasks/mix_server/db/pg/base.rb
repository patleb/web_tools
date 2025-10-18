module Db
  module Pg
    class Base < ActiveTask::Base
      class Failed < ::StandardError; end

      def self.ignored_errors
        [
          "pg_dump: executing SELECT pg_catalog.set_config('search_path', '', false);",
          /pg_dump: (last built-in|reading|identifying|finding|flagging|saving|dumping)/,
          /pg_restore: (connecting|creating|executing|processing|implied|disabling|enabling)/,
          /pg_restore: while PROCESSING TOC/,
          /pg_restore: from TOC entry/,
          /pg_restore: warning: errors ignored/,
          /Error while PROCESSING TOC/,
          /Error from TOC entry/,
          /ERROR: +must be owner of extension plpgsql/,
          /COMMENT ON EXTENSION plpgsql/,
          /ALTER TABLE.+OWNER TO/,
          /WARNING: errors ignored/,
          /ERROR:.+does not exist/,
          /NOTICE:.+already exists, skipping/,
          /NOTICE: +truncate/,
          /STATEMENT: +TRUNCATE/,
          /Command was: (COPY|ALTER TABLE|CREATE INDEX)/,
          'ERROR:  unrecognized configuration parameter "idle_in_transaction_session_timeout"',
          'ERROR:  must be owner of extension plpgsql',
          'ERROR:  must be owner of schema public',
          'ERROR:  schema "public" already exists',
          'WARNING:  no privileges could be revoked for "public"',
          'WARNING:  no privileges were granted for "public"',
          "tar: Removing leading `/' from member names",
          "unpigz: warning: <stdin>: trailing junk was ignored",
        ]
      end

      def self.sanitized_lines
        {
          psql_url: /postgresql:.+:543\d/,
          pg_password: /PGPASSWORD=\w+;/,
        }
      end

      def self.pg_options
        ENV['PG_OPTIONS']
      end

      def pg_options
        "#{self.class.pg_options} #{options.pg_options}"
      end

      def psql!(command, *sh_rest, **options)
        psql(command, *sh_rest, raise_on_error: true, **options)
      end

      def psql(command, *sh_rest, raise_on_error: false, sudo: false, silent: false)
        cmd = Sh.psql command, (Setting.db_url unless sudo)
        cmd = [cmd, *sh_rest, (' > /dev/null' if silent)].join(' ')
        stdout, stderr, _status = Open3.capture3(cmd)
        notify!(cmd, stderr) if raise_on_error && notify?(stderr)
        stdout.strip
      end

      protected

      def notify?(stderr)
        stderr.lines.lazy.map(&:strip).any?{ |line| output_error? line }
      end

      def notify!(cmd, stderr)
        cmd = self.class.sanitized_lines.each_with_object(cmd) do |(id, match), memo|
          memo.gsub! match, "[#{id}]"
        end
        stderr = stderr.lines.map(&:strip).select{ |line| output_error? line }.join("\n")
        raise Failed, "[\n#{cmd}\n][\n#{stderr}\n]"
      end

      def output_error?(line)
        line.present? && self.class.ignored_errors.none? do |ignored_error|
          ignored_error.is_a?(Regexp) ? line.match?(ignored_error) : line == ignored_error
        end
      end

      def pg_data_dir
        @pg_data_dir ||= Pathname.new(`sudo cat #{Sunzistrano.owner_path :metadata_dir, 'pg_data_dir'}`.strip)
      end

      def su_postgres(cmd)
        <<-CMD.squish
          cd /tmp && sudo su postgres -c 'set -e; #{cmd}'
        CMD
      end
    end
  end
end
