namespace :monit do
  desc 'capture monitoring/performance'
  task :capture => :environment do
    Monit.capture
  end

  desc 'cleanup old monitoring/performance records'
  task :cleanup => :environment do
    Monit.cleanup
  end

  desc 'database missing indexes'
  task :missing_indexes => :environment do
    tables = Monit::Postgres::Table.missing_indexes.map do |table|
      { table: table.id, estimated_rows: table.estimated_rows, index_usage: table.index_usage }.pretty_hash(sort: false)
    end
    puts tables
  end

  desc 'database suggested indexes'
  task :suggested_indexes => :environment do
    indexes = Monit::Postgres::Query.suggested_indexes.map do |index|
      if index[:using] && index[:using] != "btree"
        using = ", using: #{index[:using].inspect}"
      end
      if index[:columns].size == 1
        columns = ", #{index[:columns].first.inspect}"
      else
        columns = ", [#{index[:columns].map(&:to_sym).map(&:inspect).join(", ")}]"
      end
      "add_index #{index[:table].to_sym.inspect}#{columns}#{using}, algorithm: :concurrently"
    end
    puts indexes
  end
end
