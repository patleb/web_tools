namespace :check do
  task :capture => :environment do
    Checks::Postgres::Database.capture
  end

  task :cleanup => :environment do
    Checks::Postgres::Database.cleanup
  end

  task :suggested_indexes => :environment do
    indexes = Checks::Postgres::Query.suggested_indexes.map do |index|
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
