module ExtRake
  module Pg
    module Rescuable
      extend ActiveSupport::Concern

      class Failed < ::StandardError; end

      class_methods do
        def ignored_errors
          [
            /pg_restore: (connecting|creating|executing|processing|implied)/,
            /Error while PROCESSING TOC/,
            /Error from TOC entry/,
            /ERROR:  must be owner of extension plpgsql/,
            /COMMENT ON EXTENSION plpgsql/,
            /ALTER TABLE.+OWNER TO/,
            /WARNING: errors ignored/,
            /ERROR:.+does not exist/,
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
            psql_url: /postgresql:.+:5432/,
            pg_password: /PGPASSWORD=\w+;/,
          }
        end
      end

      protected

      def notify?(stderr)
        stderr.strip.split("\n").lazy.map(&:strip).any?{ |line| ignored_error? line }
      end

      def notify!(cmd, stderr)
        cmd = self.class.sanitized_lines.each_with_object(cmd) do |(id, match), memo|
          memo.gsub! match, "[#{id}]"
        end
        stderr = stderr.strip.split("\n").map(&:strip).select{ |line| ignored_error? line }.join("\n")
        raise Failed, "[#{cmd}]\n\n#{stderr}"
      end

      def ignored_error?(line)
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
