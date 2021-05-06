module Checks
  module Postgres
    class Table < Base
      alias_attribute :table, :id
      attribute       :last_vacuum, :datetime
      attribute       :last_analyze, :datetime
      attribute       :vacuum_fraction, :float
      attribute       :estimated_rows, :integer
      attribute       :daily_bytes, :integer
      attribute       :weekly_bytes, :integer
      attribute       :unused, :boolean
      attribute       :bloat_bytes, :integer
      attribute       :total_bytes, :integer
      attribute       :cache_hit, :float
      attribute       :index_usage, :float

      validate :analyze

      def self.list
        tables = db.maintenance_info.map do |row|
          row.tap do |item|
            item[:last_vacuum] = [item.delete(:last_autovacuum), item[:last_vacuum]].compact.max
            item[:last_analyze] = [item.delete(:last_autoanalyze), item[:last_analyze]].compact.max
            vacuum_fraction = item.delete(:dead_rows).to_f / item.delete(:live_rows)
            item[:vacuum_fraction] = vacuum_fraction.nan? ? 0.0 : vacuum_fraction
          end
        end
        tables_stats = db.table_stats(table: tables.map(&:[].with(:table)))
        if Setting[:pgstats_enabled]
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
          next unless row[:bloat] >= Setting[:check_table_bloat_factor]
          next unless (bloat_bytes = row[:waste].to_bytes) >= Setting[:check_table_bloat_bytes]
          memo[row[:object_name]] = { bloat_bytes: bloat_bytes }
        end
        index_usage = db.index_usage.each_with_object({}) do |row, memo|
          next if (percent = row[:percent_of_times_index_used]) == 'Insufficient data'
          memo[row[:table]] = percent.to_f.ceil(2)
        end
        unused_tables = db.unused_tables.map{ |row| [row[:table], true] }.to_h
        table_caching = db.table_caching.map{ |row| [row[:table], row[:hit_rate].to_f.ceil(2)] }.to_h
        tables.zip(tables_stats, daily_growth || [], weekly_growth || []).map do |(table, stats, daily, weekly)|
          id, table = table[:table], table.merge(stats, daily || {}, weekly || {})
          unused, bloat_bytes, cache_hit = !!unused_tables[id], bloated_tables[id] || 0, table_caching[id]
          {
            id: id, unused: unused, bloat_bytes: bloat_bytes, total_bytes: table[:size_bytes],
            cache_hit: cache_hit, index_usage: index_usage[id],
            **table.slice(:last_vacuum, :last_analyze, :vacuum_fraction, :estimated_rows, :daily_bytes, :weekly_bytes)
          }
        end
      end

      def self.bloat_bytes
        sum(&:bloat_bytes)
      end

      def self.total_bytes
        sum(&:total_bytes)
      end

      def self.estimated_rows
        sum(&:estimated_rows)
      end

      def warning?
        unused? || bloat?
      end

      def bloat?
        !!bloat_bytes
      end

      def bad_cache_hit_rate?
        cache_hit < db.cache_hit_rate_threshold
      end

      def analyze
        old_stderr, $stderr = $stderr, StringIO.new
        db.analyze_tables(tables: [id])
        if (error_message = $stderr.string).present?
          errors.add :base, error_message
        end
      ensure
        $stderr = old_stderr
      end
    end
  end
end
