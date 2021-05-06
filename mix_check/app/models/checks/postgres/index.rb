module Checks
  module Postgres
    class Index < Base
      attribute :table
      attribute :columns, :array
      attribute :using
      attribute :unique, :boolean
      attribute :primary, :boolean
      attribute :not_valid, :boolean
      attribute :duplicate, :boolean
      attribute :unused, :boolean
      attribute :bloat_bytes, :integer
      attribute :total_bytes, :integer
      attribute :cache_hit, :float

      def self.list
        duplicate_indexes = db.duplicate_indexes(indexes: db_indexes).each_with_object({}) do |row, memo|
          memo[row[:unneeded_index][:name]] = true
          memo[row[:covering_index][:name]] = true
        end
        unused_indexes = db.unused_indexes(max_scans: 0).map{ |row| [row[:index], true] }.to_h
        bloated_indexes = db.index_bloat.map(&:values_at.with(:index, :bloat_bytes)).to_h
        relation_sizes = db.relation_sizes(:index).map(&:values_at.with(:relation, :size_bytes)).to_h
        index_caching = db.index_caching.map{ |row| [row[:index], row[:hit_rate].to_f.ceil(2)] }.to_h
        db_indexes.map do |row|
          id = row[:name]
          not_valid = !row[:valid] && !row[:creating]
          duplicate, unused, bloat_bytes = duplicate_indexes[id], unused_indexes[id], bloated_indexes[id] || 0
          cache_hit = index_caching[id]
          {
            id: id, not_valid: not_valid, duplicate: !!duplicate, unused: !!unused,
            bloat_bytes: bloat_bytes, total_bytes: relation_sizes[id], cache_hit: cache_hit,
            columns: row[:columns].map{ |c| c.sub(/^CREATE INDEX \w+ ON public.\w+ USING \w+ /, '') },
            **row.slice(:table, :using, :unique, :primary)
          }
        end
      end

      def self.bloat_bytes
        sum(&:bloat_bytes)
      end

      def self.total_bytes
        sum(&:total_bytes)
      end

      def error?
        not_valid?
      end

      def warning?
        duplicate? || unused? || bloat? || bad_cache_hit_rate?
      end

      def bloat?
        !!bloat_bytes
      end

      def bad_cache_hit_rate?
        cache_hit < db.cache_hit_rate_threshold
      end
    end
  end
end
