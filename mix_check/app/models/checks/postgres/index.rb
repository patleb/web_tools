module Checks
  module Postgres
    class Index < Base
      attribute :table
      attribute :columns, :array
      attribute :using
      attribute :unique, :boolean
      attribute :primary, :boolean
      attribute :valid, :boolean
      attribute :distinct, :boolean
      attribute :used, :boolean
      attribute :compact, :boolean
      attribute :bloat_bytes, :integer
      attribute :total_bytes, :integer

      def self.list
        duplicate_indexes = db.duplicate_indexes(indexes: Database.indexes).each_with_object({}) do |row, memo|
          memo[row[:unneeded_index][:name]] = true
          memo[row[:covering_index][:name]] = true
        end
        unused_indexes = db.unused_indexes(max_scans: 0).map{ |row| [row[:index], true] }.to_h
        bloated_indexes = db.index_bloat.map{ |row| [row.delete(:index), row] }.to_h
        size_of_indexes = exec_statement(:index_size).map(&:values_at.with(:name, :size)).to_h
        Database.indexes.map do |row|
          id = row[:name]
          invalid = !row[:valid] && !row[:creating]
          duplicate, unused, bloated = duplicate_indexes[id], unused_indexes[id], bloated_indexes[id]
          bloat_bytes, total_bytes = bloated.values_at(:bloat_bytes, :index_bytes) if bloated
          {
            id: id, valid: !invalid, distinct: !duplicate, used: !unused, compact: !bloated,
            bloat_bytes: bloat_bytes, total_bytes: total_bytes || size_of_indexes[id].to_bytes,
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

      def invalid?
        !valid?
      end

      def duplicate?
        !distinct?
      end

      def unused?
        !used?
      end

      def bloat?
        !compact?
      end
    end
  end
end
