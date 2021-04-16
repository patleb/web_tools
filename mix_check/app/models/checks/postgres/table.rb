module Checks
  module Postgres
    class Table < Base
      attribute       :schema
      alias_attribute :table, :id
      attribute       :last_vacuum, :datetime
      attribute       :last_analyze, :datetime
      attribute       :dead_rows, :float
      attribute       :estimated_rows, :integer
      attribute       :size_bytes, :integer
      attribute       :daily_bytes, :integer
      attribute       :weekly_bytes, :integer

      def self.list
        tables = database.maintenance_info.map! do |row|
          row.tap do |item|
            item[:last_vacuum] = [item.delete(:last_autovacuum), item[:last_vacuum]].compact.max
            item[:last_analyze] = [item.delete(:last_autoanalyze), item[:last_analyze]].compact.max
            item[:dead_rows] = item[:dead_rows].to_f / item.delete(:live_rows)
          end
        end
        tables_stats = database.table_stats(table: tables.map(&:[].with(:table)))
        if ::Setting[:pgstats_enabled]
          tables_sizes = tables_stats.map{ |row| row.slice(:schema, :size_bytes).merge(relation: row[:table]) }
          daily_growth = database.space_growth(days: 1, relation_sizes: tables_sizes).map! do |row|
            row.tap{ |item| item[:daily_bytes] = item.delete(:growth_bytes) }
          end
          weekly_growth = database.space_growth(days: 7, relation_sizes: tables_sizes).map! do |row|
            row.tap{ |item| item[:weekly_bytes] = item.delete(:growth_bytes) }
          end
        end
        tables.zip(tables_stats, daily_growth || {}, weekly_growth || {}).map do |(table, stats, daily, weekly)|
          table = table.merge(stats, daily, weekly).except(:relation)
          { id: table.delete(:table), **table }
        end
      end

      def self.stats
        { table: all.select_map{ |item| [item.id, item.slice(:size_bytes, :daily_bytes, :weekly_bytes)] if item.schema == 'public' }.to_h }
      end
    end
  end
end
