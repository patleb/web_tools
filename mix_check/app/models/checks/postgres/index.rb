module Checks
  module Postgres
    class Index < Base
      attribute :table
      attribute :columns, :array
      attribute :using
      attribute :unique, :boolean
      attribute :primary, :boolean
      attribute :invalid, :boolean
      attribute :duplicate, :boolean
      attribute :unused, :boolean
      attribute :bloat_bytes, :integer
      attribute :total_bytes, :integer
      attribute :cache_usage, :float

      def self.list
        duplicate_indexes = db.duplicate_indexes(indexes: Database.indexes).each_with_object({}) do |row, memo|
          memo[row[:unneeded_index][:name]] = true
          memo[row[:covering_index][:name]] = true
        end
        unused_indexes = db.unused_indexes(max_scans: 0).map{ |row| [row[:index], true] }.to_h
        bloated_indexes = db.index_bloat.map(&:values_at.with(:index, :bloat_bytes)).to_h
        relation_sizes = db.relation_sizes(:index).map(&:values_at.with(:relation, :size_bytes)).to_h
        index_caching = db.index_caching.map{ |row| [row[:index], row[:hit_rate].to_f.ceil(2)] }.to_h
        Database.indexes.map do |row|
          id = row[:name]
          invalid = !row[:valid] && !row[:creating]
          duplicate, unused, bloat_bytes = duplicate_indexes[id], unused_indexes[id], bloated_indexes[id]
          {
            id: id, cache_usage: index_caching[id], invalid: invalid, duplicate: !!duplicate, unused: !!unused,
            bloat_bytes: bloat_bytes, total_bytes: relation_sizes[id],
            **row.slice(:table, :columns, :using, :unique, :primary)
          }
        end
      end

      def self.issues
        { index_invalid: any?(&:invalid?) }
      end

      def self.warnings
        {
          index_duplicate: any?(&:duplicate?),
          index_unused: any?(&:unused?),
          index_bloat: any?(&:bloat?),
        }
      end

      def self.stats
        { index: all.select_map{ |item| [item.id, { size: item.total_bytes, bloat: item.bloat_bytes }] if item.bloat? }.to_h }
      end

      def bloat?
        !!bloat_bytes
      end
    end
  end
end
