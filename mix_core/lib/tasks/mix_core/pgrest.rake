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

  desc 'reload pgrest schema cache'
  task :reload_pgrest => :environment do
    if Setting[:pgrest_enabled] && Rails::Env.dev_or_test?
      sh 'kill -s USR1 $(pgrep postgrest) || :'
    end
  end
end
Rake::Task['db:drop'].enhance ['db:drop_pgrest']
Rake::Task['db:migrate'].enhance{ Rake::Task['db:reload_pgrest'].invoke }
