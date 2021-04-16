module Checks
  module Postgres
    class Cache < Base
      attribute :percent, :float

      def self.list
        [
          { id: 'table', percent: (database.table_hit_rate || 0) * 100.0 },
          { id: 'index', percent: (database.index_hit_rate || 0) * 100.0 },
        ]
      end

      def self.issues
        { cache_index: find('index').bad_hit_rate? }
      end

      def self.warnings
        { cache_table: find('table').bad_hit_rate? }
      end

      def self.stats
        { cache: all.select_map{ |item| [item.id, item.slice(:percent)] if item.bad_hit_rate? }.to_h }
      end

      def bad_hit_rate?
        percent < self.class.database.cache_hit_rate_threshold.to_f
      end
    end
  end
end
