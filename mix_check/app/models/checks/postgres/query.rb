module Checks
  module Postgres
    class Query < Base
      WALSENDER  = 'walsender'
      AUTOVACUUM = 'autovacuum:'
      ANALYZE    = 'ANALYZE '
      VISUALIZE  = '(ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) '
      BIND_ERROR = 'bind message supplies 0 parameters'
      DENIED_OPS = /INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|TRUNCATE|REINDEX|COPY|GRANT|REVOKE|VACUUM|ANALY[ZS]E/

      attribute :user
      attribute :source
      attribute :state
      attribute :waiting, :boolean
      attribute :query
      attribute :duration_ms, :float
      attribute :started_at, :datetime
      attribute :total_percent, :float
      attribute :calls, :integer
      attribute :walsender, :boolean
      attribute :autovacuum, :boolean
      attribute :long, :boolean
      attribute :slow, :boolean
      attribute :blocking, :boolean
      attribute :blocked, :boolean
      attribute :lock_mode
      attribute :analyze, :boolean
      attribute :visualize, :boolean
      attribute :explanation

      validate :explain

      def self.list
        if ::Setting[:pgstats_enabled]
          slow_queries = db.query_stats(
            historical: true,
            start_at: 24.hours.ago,
            min_calls: db.slow_query_calls.to_i,
            min_average_time: db.slow_query_ms.to_f
          ).map do |row|
            {
              id: row[:query_hash], slow: true, duration_ms: row[:average_time],
              **row.slice(:user, :query, :total_percent, :calls)
            }
          end
        end
        blocked_queries, blocking_queries = db.blocked_queries.map.each_with_object([{}, {}]) do |row, memo|
          memo[0][row[:blocked_pid]] = row[:blocked_mode]
          memo[1][row[:blocking_pid]] = row[:blocking_mode]
        end
        long_queries = db.running_queries.select_map do |row|
          next unless row[:state]
          walsender, autovacuum = row[:backend_type] == WALSENDER, row[:query].starts_with?(AUTOVACUUM)
          long = !walsender && !autovacuum && (row[:duration_ms] / 1000.0).to_i > db.long_running_query_sec
          {
            id: row.delete(:pid), walsender: walsender, autovacuum: autovacuum, long: long,
            **row.slice(:user, :source, :state, :waiting, :query, :duration_ms, :started_at)
          }
        end
        (slow_queries || []).concat(long_queries).map! do |row|
          pid = row[:id]
          case
          when (lock_mode = blocked_queries[pid])  then row.merge! blocked: true, lock_mode: lock_mode
          when (lock_mode = blocking_queries[pid]) then row.merge! blocking: true, lock_mode: lock_mode
          else row
          end
        end
      end

      def self.issues
        { query_long: any?(&:long?) }
      end

      def self.warnings
        { query_slow: any?(&:slow?) }
      end

      def self.stats
        {
          query_long: long.map{ |item| [item.id, item.except(:id).reject{ |_k, v| v.blank? }] }.to_h,
          query_slow: slow.map{ |item| [item.id, item.except(:id).reject{ |_k, v| v.blank? }] }.to_h,
        }
      end

      def self.long
        where(long: true)
      end

      def self.slow
        where(slow: true)
      end

      def self.kill_long
        long.map(&:kill)
      end

      def self.vacuum_progress
        m_access(:vacuum_progress) do
          db.vacuum_progress.index_by{ |q| q[:pid] }
        end
      end

      def self.suggested_indexes
        slow_queries = all.select_map{ |item| item.query if item.slow? }
        suggested_indexes_by_query = db.suggested_indexes_by_query(queries: slow_queries, indexes: Database.indexes)
        db.suggested_indexes(suggested_indexes_by_query: suggested_indexes_by_query, indexes: Database.indexes)
      end

      def explain
        if walsender? || autovacuum? || self.class.db.filter_data
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

      def kill
        self.class.db.kill(id) unless slow?
      end
      alias_method :destroy, :kill

      def vacuum_progress
        self.class.vacuum_progress.dig(id, :phase) unless slow?
      end
    end
  end
end
