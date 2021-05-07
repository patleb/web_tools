module Checks
  module Postgres
    class Query < Base
      ANALYZE    = 'ANALYZE '
      VISUALIZE  = '(ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) '
      BIND_ERROR = 'bind message supplies 0 parameters'
      DENIED_OPS = /INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|TRUNCATE|REINDEX|COPY|GRANT|REVOKE|VACUUM|ANALY[ZS]E/

      alias_attribute :pid, :id
      attribute       :source
      attribute       :state
      attribute       :waiting, :boolean
      attribute       :blocking, :boolean
      attribute       :blocked, :boolean
      attribute       :lock_mode
      attribute       :query
      attribute       :long_running, :boolean
      attribute       :historical, :boolean
      attribute       :duration_ms, :float
      attribute       :started_at, :datetime
      attribute       :total_percent, :float
      attribute       :calls, :integer
      attribute       :analyze, :boolean
      attribute       :visualize, :boolean
      attribute       :explanation

      validate :explain

      scope :slow,         -> { where(long_running: false) }
      scope :long_running, -> { where(long_running: true) }
      scope :historical,   -> { where(historical: true) }

      def self.list
        pids = {}
        queries = db.running_queries(min_duration: db.slow_query_ms / 1000.0).select_map do |row|
          next unless row[:state]
          next unless owner?(row) && !(autovacuum?(row) || walsender?(row))
          pids[row[:pid]] = true
          { id: row[:pid], **row.slice(:query, :source, :state, :waiting, :started_at, :duration_ms) }
        end
        blocked_queries, blocking_queries = db.blocked_queries.map.each_with_object([{}, {}]) do |row, memo|
          memo[0][row[:blocked_pid]] = row[:blocked_mode]
          memo[1][row[:blocking_pid]] = row[:blocking_mode]
        end
        if Setting[:pgstats_enabled]
          historical_queries = db.query_stats(
            historical: true,
            start_at: (Setting[:check_log_interval] + 30.seconds).ago,
            min_calls: db.slow_query_calls.to_i,
            min_average_time: db.slow_query_ms.to_f
          ).select_map do |row|
            next unless owner?(row) && !autovacuum?(row)
            id = row[:query_hash]
            id = "##{id}" if pids[id]
            { id: id, **row.slice(:query, :total_percent, :calls), duration_ms: row[:average_time], historical: true }
          end
        end
        (historical_queries || []).concat(queries).map! do |row|
          row[:long_running] = (row[:duration_ms] / 1000.0).to_i > db.long_running_query_sec
          case
          when (lock_mode = blocked_queries[row[:id]])  then row.merge! blocked: true, lock_mode: lock_mode
          when (lock_mode = blocking_queries[row[:id]]) then row.merge! blocking: true, lock_mode: lock_mode
          else row
          end
        end
      end

      def self.autovacuum?(row)
        row[:query].starts_with? 'autovacuum:'
      end

      def self.walsender?(row)
        row[:backend_type] == 'walsender'
      end

      def self.vacuum_progress
        m_access(:vacuum_progress) do
          db.vacuum_progress.index_by{ |q| q[:pid] }
        end
      end

      def self.suggested_indexes
        Setting.with(freeze: false) do |setting|
          setting[:check_log_interval] = 24.hours
          suggested_indexes_by_query = db.suggested_indexes_by_query(queries: historical.map(&:query), indexes: db_indexes)
          db.suggested_indexes(suggested_indexes_by_query: suggested_indexes_by_query, indexes: db_indexes)
        end
      end

      def self.duration_ms
        historical.slow.average(&:duration_ms)
      end

      # NOTE might need to restart passenger and job:watch
      def self.kill_all
        db.kill_all
      end

      def self.kill_long_running
        long_running.each(&:kill)
      end

      def kill
        self.class.db.kill(id) unless historical?
      end
      alias_method :destroy, :kill

      def vacuum_progress
        self.class.vacuum_progress.dig(id, :phase) unless historical?
      end

      def explain
        if self.class.db.filter_data
          errors.add :query, :denied
          return
        end
        prefix = case
          when visualize? then VISUALIZE
          when analyze?   then ANALYZE
          end
        if prefix && (query.exclude?('SELECT') || query.match?(DENIED_OPS))
          errors.add :query, :denied
          return
        end
        self.explanation = self.class.db.explain("#{prefix}#{query}")
      rescue ActiveRecord::StatementInvalid => e
        if e.message.include? BIND_ERROR
          errors.add :query, :params
        else
          errors.add :query, e.message
        end
      end

      alias_method :long_running_warning?, :long_running?
    end
  end
end
