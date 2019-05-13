module Db
  module Pg
    class Sqlite < Base
      def self.steps
        [:convert]
      end

      def convert
        ENV['PG_OPTIONS'] = '--data-only --inserts'
        invoke 'db:pg:dump'

        dump = "#{Rails.root}/db/dump.pg"
        tmp = Tempfile.new('dump.pg')
        begin
          tmp.puts 'BEGIN;'
          File.open(dump, 'r').each do |line|
            if line.match? /^(SET|SELECT pg_catalog\.setval)/
              # skip
            else
              line.gsub!(/'true'/, "'t'")
              line.gsub!(/'false'/, "'f'")
              tmp.puts line
            end
          end
          tmp.puts 'END;'
          tmp.close
          FileUtils.mv(tmp.path, dump)
        ensure
          tmp.close
          tmp.unlink
        end
      end
    end
  end
end
