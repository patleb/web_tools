namespace :db do
  desc 'drop pgrest'
  task :drop_pgrest => :environment do
    if Setting[:pgrest_enabled]
      ActiveRecord::Base.connection.exec_query 'DROP SCHEMA IF EXISTS api CASCADE'
      unless Rails.env.test?
        ActiveRecord::Base.connection.exec_query "DROP ROLE IF EXISTS #{Setting[:pgrest_db_username]}"
        ActiveRecord::Base.connection.exec_query 'DROP ROLE IF EXISTS web_anon' rescue nil
      end
    end
  end
end
Rake::Task['db:drop'].enhance ['db:drop_pgrest']
