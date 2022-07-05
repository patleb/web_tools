namespace :db do
  namespace :postgis do
    desc 'upgrade postgis'
    task :upgrade => :environment do
      ApplicationRecord.connection.exec_query <<-SQL.strip_sql
        SELECT postgis_extensions_upgrade()
      SQL
    end
  end
end
