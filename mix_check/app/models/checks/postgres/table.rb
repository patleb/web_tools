module Checks
  module Postgres
    class Table < Base
      alias_attribute :table, :id
      attribute       :compact, :boolean
      attribute       :bloat_bytes, :integer
      attribute       :last_vacuum, :datetime
      attribute       :last_analyze, :datetime
      attribute       :vacuum_fraction, :float
      attribute       :estimated_rows, :integer
      attribute       :size_bytes, :integer
      attribute       :daily_bytes, :integer
      attribute       :weekly_bytes, :integer

      def self.list
        tables = db.maintenance_info.map! do |row|
          row.tap do |item|
            item[:last_vacuum] = [item.delete(:last_autovacuum), item[:last_vacuum]].compact.max
            item[:last_analyze] = [item.delete(:last_autoanalyze), item[:last_analyze]].compact.max
            item[:vacuum_fraction] = item.delete(:dead_rows).to_f / item.delete(:live_rows)
          end
        end
        tables_stats = db.table_stats(table: tables.map(&:[].with(:table)))
        if ::Setting[:pgstats_enabled]
          tables_sizes = tables_stats.map{ |row| row.slice(:schema, :size_bytes).merge(relation: row[:table]) }
          daily_growth = db.space_growth(days: 1, relation_sizes: tables_sizes).map! do |row|
            row.tap{ |item| item[:daily_bytes] = item.delete(:growth_bytes) }
          end
          weekly_growth = db.space_growth(days: 7, relation_sizes: tables_sizes).map! do |row|
            row.tap{ |item| item[:weekly_bytes] = item.delete(:growth_bytes) }
          end
        end
        bloated_tables = exec_statement(:bloat).each_with_object({}) do |row, memo|
          next unless public? row, :schemaname
          next unless row[:type] == 'table'
          next unless row[:bloat] >= 10.0
          next unless (bloat_bytes = row[:waste].to_bytes).bytes_to_mb > 100.0
          memo[row[:object_name]] = { bloat_bytes: bloat_bytes }
        end
        tables.zip(tables_stats, daily_growth || [], weekly_growth || []).map do |(table, stats, daily, weekly)|
          id, table = table[:table], table.merge(stats, daily || {}, weekly || {})
          bloat_bytes = bloated_tables[id]
          {
            id: id, compact: bloat_bytes.nil?, bloat_bytes: bloat_bytes,
            **table.slice(:last_vacuum, :last_analyze, :vacuum_fraction, :estimated_rows, :size_bytes, :daily_bytes, :weekly_bytes)
          }
        end
      end

      def self.stats
        { table: all.map{ |item| [item.id, item.slice(:size_bytes, :daily_bytes, :weekly_bytes)] }.to_h }
      end

      def bloat?
        !compact?
      end
    end
  end
end
