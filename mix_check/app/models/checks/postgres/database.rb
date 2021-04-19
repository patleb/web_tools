module Checks
  module Postgres
    class Database < Base
      attribute :size, :integer
      attribute :uptime, :float
      attribute :wal_size, :integer
      attribute :wal_growth, :integer
      attribute :buffers, :boolean
      attribute :checksum, :boolean
      attribute :table_cache, :float
      attribute :index_cache, :float

      def self.list
        [{
          id: db_name, size: total_size.to_bytes, uptime: uptime, wal_size: wal_size, wal_growth: wal_growth,
          buffers: !written_too_many_buffers?, checksum: !checksum_failed?,
          table_cache: ((db.table_hit_rate || 0) * 100.0).to_f.ceil(2),
          index_cache: ((db.index_hit_rate || 0) * 100.0).to_f.ceil(2),
        }]
      end

      def self.issues
        { index_cache: first.bad_hit_rate?(:index) }
      end

      def self.warnings
        { table_cache: first.bad_hit_rate?(:table) }
      end

      def self.db_name
        @@db_name ||= db.send(:connection_model).connection_db_config.configuration_hash[:database]
      end

      def self.indexes
        m_access(:indexes){ db.indexes.select{ |row| public? row, :schema } }
      end

      def self.total_size
        m_access(:total_size){ db.database_size }
      end

      def self.uptime
        exec_statement(:postmaster_uptime, one: true)[:seconds]
      end

      def self.wal_size
        wal_activity[:total_size_bytes].to_i
      end

      def self.wal_growth
        wal_activity[:last_5_min_size_bytes].to_i
      end

      def self.wal_activity
        m_access(:wal_activity){ exec_statement(:wal_activity, one: true) }
      end

      # reset_stat_bgwriter once resolved
      def self.written_too_many_buffers?
        bgwriter[:maxwritten_clean] > 0
      end

      def self.bgwriter
        exec_statement(:stat_bgwriter, one: true)
      end

      def self.reset_stat_bgwriter
        ar_connection.exec_query("SELECT pg_stat_reset_shared('bgwriter')::TEXT")
        true
      end

      # reset_stat_database once resolved
      def self.checksum_failed?
        checksum_failure[:count].to_i > 0
      end

      def self.checksum_failure
        exec_statement(:data_checksum_failure).find{ |row| row[:dbname] == db_name }.except(:dbname)
      end

      def self.reset_stat_database
        ar_connection.exec_query("SELECT pg_stat_reset()::TEXT")
        true
      end

      def bad_hit_rate?(type)
        send("#{type}_cache") < self.class.db.cache_hit_rate_threshold.to_f
      end
    end
  end
end
