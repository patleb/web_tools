module MixBackup
  module Restore
    class PostgreSQL < Base
      def self.steps
        super + [:analyse]
      end

      def self.args
        {
          model:      ['--model=MODEL',     'Backup model'],
          version:    ['--version=VERSION', 'Backup version'],
          drop_all:   ['--[no-]drop-all',   'Drop all before restore'],
          pg_restore: ['--[no-]pg-restore', 'Use pg_restore'],
          db:         ['--db=DB',           'DB type (ex.: --db=record would use Record::Base connection'],
        }
      end

      def self.backup_type
        'databases'
      end

      def self.pg_options
        ENV['PG_OPTIONS'].presence
      end

      protected

      def restore_cmd
        drop_all = options.drop_all ? "#{drop_all_cmd} &&" : ''

        if Gem.win_platform?
          raise NoWindowsSupport if options.pg_restore

          backup = extract_path.join("PostgreSQL.sql")
          %{#{drop_all} psql #{self.class.pg_options || '--quiet'} "#{ExtRake.config.db_url}" < "#{backup}"}
        else
          backup = extract_path.join("PostgreSQL.sql.gz")
          if options.pg_restore
            %{#{drop_all} zcat "#{backup}" | pg_restore #{self.class.pg_options} -d "#{ExtRake.config.db_url}"}
          else
            %{#{drop_all} zcat "#{backup}" | psql #{self.class.pg_options || '--quiet'} "#{ExtRake.config.db_url}"}
          end
        end
      end

      def drop_all_cmd
        %{psql --quiet -c "DROP OWNED BY CURRENT_USER;" "#{ExtRake.config.db_url}"}
      end

      def analyse
        # TODO add admin button to run passenger-restart to free some memory
      end
    end
  end
end
