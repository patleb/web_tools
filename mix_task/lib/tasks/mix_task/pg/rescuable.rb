module MixTask
  module Pg
    module Rescuable
      extend ActiveSupport::Concern

      class Failed < ::StandardError; end

      class_methods do
        def ignored_errors
          [
            /pg_restore: (connecting|creating|executing|processing|implied|disabling|enabling)/,
            /Error while PROCESSING TOC/,
            /Error from TOC entry/,
            /ERROR:  must be owner of extension plpgsql/,
            /COMMENT ON EXTENSION plpgsql/,
            /ALTER TABLE.+OWNER TO/,
            /WARNING: errors ignored/,
            /ERROR:.+does not exist/,
            /NOTICE:.+already exists, skipping/,
            'Command was: COPY _timescaledb_catalog.telemetry_metadata (key, value) FROM stdin;',
            'ERROR:  unrecognized configuration parameter "idle_in_transaction_session_timeout"',
            'ERROR:  must be owner of extension plpgsql',
            'ERROR:  must be owner of schema public',
            'ERROR:  schema "public" already exists',
            'WARNING:  no privileges could be revoked for "public"',
            'WARNING:  no privileges were granted for "public"',
            "tar: Removing leading `/' from member names",
          ]
        end

        def sanitized_lines
          {
            psql_url: /postgresql:.+:543\d/,
            pg_password: /PGPASSWORD=\w+;/,
          }
        end
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
          if ignored_error.is_a? Regexp
            line.match ignored_error
          else
            line == ignored_error
          end
        end
      end
    end
  end
end
