# TODO https://habr.com/en/company/postgrespro/blog/494464/
module Monits
  module Postgres
    class Database < Base
      alias_attribute :name, :id
      attribute       :size, :integer
      attribute       :uptime, :float
      attribute       :wal_size, :integer
      attribute       :wal_growth, :integer
      attribute       :corrupted, :boolean
      attribute       :last_bgwriter_reset, :datetime
      attribute       :last_stats_reset, :datetime
      attribute       :table_cache, :float
      attribute       :index_cache, :float
      attribute       :temp_files, :integer
      attribute       :temp_bytes, :integer

      nests_many :connections,             default: proc { Connection.all }
      nests_many :indexes,                 default: proc { Index.all }
      nests_many :invalid_constraints,     default: proc { InvalidConstraint.all }
      nests_many :queries,                 default: proc { Query.all }
      nests_many :replication_slots,       default: proc { ReplicationSlot.all }
      nests_many :sequences,               default: proc { Sequence.all }
      nests_many :tables,                  default: proc { Table.all }
      nests_many :transaction_wraparounds, default: proc { TransactionWraparound.all }

      validates :corrupted, absence: true
      validate  :connections_check
      validates :indexes, check: true
      validates :invalid_constraints, absence: true
      validates :replication_slots, check: true
      validates :sequences, check:true
      validates :transaction_wraparounds, check: true

      delegate_to :connections, :idle, :total, prefix: true
      delegate_to :connections_idle, :total, prefix: true

      def self.list
        table_cache = ((db.table_hit_rate || 0) * 100.0).to_f.ceil(2)
        index_cache = ((db.index_hit_rate || 0) * 100.0).to_f.ceil(2)
        corrupted = exec_statement(:data_checksum_failure).find{ |row| row[:dbname] == db_name }[:count].to_i > 0
        wal_size, wal_growth = exec_statement_one(:wal_activity).values_at(:total_size_bytes, :last_5_min_size_bytes)
        [{
          id: db_name, size: db.database_size, uptime:  exec_statement_one(:postmaster_uptime)[:seconds],
          wal_size: wal_size.to_i, wal_growth: wal_growth.to_i, corrupted: corrupted,
          last_bgwriter_reset: exec_statement_one(:stat_bgwriter)[:stats_reset],
          last_stats_reset: db.last_stats_reset_time,
          table_cache: table_cache, index_cache: index_cache,
          **exec_statement_one(:stat_database).slice(:temp_files, :temp_bytes),
        }]
      end

      def self.capture?
        db_host == '127.0.0.1'
      end

      def self.settings
        m_access(:settings) do
          { version: db.server_version }.merge!(
            db.settings,
            db.vacuum_settings,
            db.autovacuum_settings,
            db.send(:fetch_settings, %i(effective_io_concurrency random_page_cost))
          ).symbolize_keys
        end
      end

      # reset_stat_bgwriter once resolved
      def self.reset_stat_bgwriter
        ar_connection.exec_query("SELECT pg_stat_reset_shared('bgwriter')::TEXT")
        true
      end

      # reset_stat_database once resolved
      def self.reset_stat_database
        db.reset_stats
      end

      def self.capture
        return unless capture?
        last_query_at = PgHero::QueryStats.where(database: 'primary').order(captured_at: :desc).pick(:captured_at)
        if last_query_at.nil? || last_query_at < (5.minutes - 30.seconds).ago
          PgHero.capture_query_stats
        end
        last_space_at = PgHero::SpaceStats.where(database: 'primary').order(captured_at: :desc).pick(:captured_at)
        if last_space_at.nil? || last_space_at < (1.day - 30.seconds).ago
          PgHero.capture_space_stats
        end
        last_updated_at = LogLines::Database.last_messages(text_tiny: db_name).pick(:updated_at)
        if last_updated_at.nil? || last_updated_at < (Setting[:monit_interval] - 30.seconds).ago
          Log.database(current)
          reset
        end
      end

      def self.cleanup
        return unless capture?
        PgHero.clean_query_stats
        PgHero.clean_space_stats
      end

      def index_cache_warning?
        index_cache < db.cache_hit_rate_threshold
      end

      def connections_warning?
        connections_idle_total >= 100
      end

      private

      def connections_check
        if connections_total >= db.total_connections_threshold
          errors.add(:connections, :less_than, count: db.total_connections_threshold)
        end
      end
    end
  end
end
