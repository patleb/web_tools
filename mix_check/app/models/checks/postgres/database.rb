module Checks
  module Postgres
    class Database < Base
      attribute :size, :integer
      attribute :uptime, :float
      attribute :wal_size, :integer
      attribute :wal_growth, :integer
      attribute :write_heavy, :boolean
      attribute :corrupted, :boolean
      attribute :last_bgwriter_reset, :datetime
      attribute :last_stats_reset, :datetime
      attribute :table_cache, :float
      attribute :index_cache, :float

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
        write_heavy, last_bgwriter = exec_statement(:stat_bgwriter, one: true).values_at(:maxwritten_clean, :stats_reset)
        write_heavy = write_heavy > 0
        wal_size, wal_growth = exec_statement(:wal_activity, one: true).values_at(:total_size_bytes, :last_5_min_size_bytes)
        [{
          id: db_name, size: db.database_size, uptime:  exec_statement(:postmaster_uptime, one: true)[:seconds],
          wal_size: wal_size.to_i, wal_growth: wal_growth.to_i,
          write_heavy: write_heavy, corrupted: corrupted,
          last_bgwriter_reset: last_bgwriter, last_stats_reset: db.last_stats_reset_time,
          table_cache: table_cache, index_cache: index_cache,
        }]
      end

      def self.log_lines
        all.map do |row|
          {
            error: row.error?, warning: row.warning?,
            connections: row.connections_total, queries: row.queries.duration_ms,
            **row.slice(:id, :size, :wal_size, :write_heavy, :corrupted)
          }
        end
      end

      def self.settings
        m_access(:settings) do
          { version: db.server_version }.merge!(db.settings, db.vacuum_settings, db.autovacuum_settings).symbolize_keys
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
        last_query_at = PgHero::QueryStats.order(captured_at: :desc).pick(:captured_at)
        if last_query_at.nil? || last_query_at >= 5.minutes.ago
          PgHero.capture_query_stats
        end
        last_space_at = PgHero::SpaceStats.order(captured_at: :desc).pick(:captured_at)
        if last_space_at.nil? || last_space_at >= 1.day.ago
          PgHero.capture_space_stats
        end
      end

      def self.cleanup
        PgHero.clean_query_stats
        PgHero.clean_space_stats
      end

      def error?
        !valid?
      end

      def warning?
        super || nested_warning? || write_heavy?
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
