module Checks
  module Postgres
    class Base < Checks::Base
      delegate :db, to: :class

      def self.db
        PgHero.primary_database
      end

      def self.db_name
        @@db_name ||= db.send(:connection_model).connection_db_config.configuration_hash[:database]
      end

      def self.db_user
        @@db_user ||= db.send(:connection_model).connection_db_config.configuration_hash[:username]
      end

      def self.db_host
        @@db_host ||= db.send(:connection_model).connection_db_config.configuration_hash[:host]
      end

      def self.db_indexes
        m_access(:db_indexes){ db.indexes }
      end

      def self.ar_connection
        db.send(:connection_model).connection
      end

      def self.public?(row, schema_key = :schema)
        row[schema_key] == 'public'
      end

      def self.owner?(row)
        row[:user] == db_user
      end

      def self.exec_statement_one(name)
        exec_statement(name, one: true)
      end

      def self.exec_statement(name, one: false)
        one ? select_one(statements[name]) : select_all(statements[name])
      end

      def self.select_one(...)
        select_all(...).first
      end

      def self.select_all(sql, **options)
        db.send(:select_all, sql, **options)
      end

      ### STATEMENTS (38)
      # (ruby-pg-extras) :all_locks
      # (pgmonitor)      :archive_command_status
      # (ruby-pg-extras) :bloat
      # (ruby-pg-extras) :blocking
      # (ruby-pg-extras) :cache_hit
      # (pgmonitor)      :connection_stats
      # (pgmonitor)      :data_checksum_failure
      # (pgmonitor)      :database_locks
      # (pgmonitor)      :database_size
      # (ruby-pg-extras) :db_settings
      # (ruby-pg-extras) :extensions
      # (ruby-pg-extras) :index_cache_hit
      # (ruby-pg-extras) :index_size
      # (ruby-pg-extras) :index_usage
      # (pgmonitor)      :is_in_recovery
      # (ruby-pg-extras) :kill_all
      # (ruby-pg-extras) :locks
      # (ruby-pg-extras) :mandelbrot
      # (pgmonitor)      :postgresql_version
      # (pgmonitor)      :postmaster_runtime (deprecated)
      # (pgmonitor)      :postmaster_uptime
      # (ruby-pg-extras) :records_rank
      # (pgmonitor)      :replication_lag
      # (pgmonitor)      :replication_lag_size
      # (pgmonitor)      :replication_slots
      # (ruby-pg-extras) :seq_scans
      # (pgmonitor)      :settings_gauge
      # (pgmonitor)      :settings_pending_restart
      # (pgmonitor)      :stat_bgwriter
      # (pgmonitor)      :stat_database
      # (ruby-pg-extras) :table_cache_hit
      # (ruby-pg-extras) :table_indexes_size
      # (ruby-pg-extras) :table_size
      # (ruby-pg-extras) :total_index_size
      # (ruby-pg-extras) :total_table_size
      # (pgmonitor)      :transaction_wraparound
      # (ruby-pg-extras) :vacuum_stats
      # (pgmonitor)      :wal_activity
      def self.statements
        @@statements ||= begin
          pgmonitor_path = MixCheck::Engine.root.join('vendor/pgmonitor/exporter/postgres')
          pgmonitor = pgmonitor_path.glob('*.yml').each_with_object({}.with_keyword_access) do |yml, memo|
            yml = YAML.safe_load(yml.read)
              .transform_keys{ |key| key == 'ccp_locks' ? 'database_locks' : key.delete_prefix('ccp_') }
              .transform_values{ |hash| hash['query'].escape_newlines }
              .reject{ |_key, value| value.include? 'monitor.' }
            memo.merge! yml
          end
          pgextras_path = Gem.root('ruby-pg-extras').join('lib/ruby-pg-extras/queries')
          pgextras = pgextras_path.glob('*.sql').each_with_object({}.with_keyword_access) do |sql, memo|
            name = sql.basename('.sql').to_s
            next if (sql = sql.readlines.drop(1).join(' ').strip_sql).include? '%{'
            memo[name] = sql
          end
          pgmonitor.merge! pgextras
        end
      end
      private_class_method :statements
    end
  end
end
