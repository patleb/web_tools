namespace :db do
  task :force_environment_set => :environment do
    Rake::Task['db:environment:set'].invoke rescue nil
  end

  desc 'rollback all engine tables'
  task :rollback_engines => :environment do
    WebTools.gems.keys.select{ |name| Gem.root(name)&.join('db')&.exist? }.sort.each do |name|
      run_rake! 'db:rollback_engine', name
    end
  end

  desc 'rollback engine tables'
  task :rollback_engine, [:name] => :environment do |t, args|
    raise "unavailable gem [#{args[:name]}]" unless (gem = Gem.root(args[:name]))
    versions = gem.join('db').glob('**/*.rb').select_map do |path|
      path.basename('.rb').to_s.match(/(\d+)_\w+$/).captures.first
    end
    (versions & ActiveRecord::SchemaMigration.all_versions).sort.reverse_each do |version|
      old_version = ENV['VERSION']
      ENV['VERSION'] = version
      run_rake! 'db:migrate:down'
    ensure
      ENV['VERSION'] = old_version if old_version
    end
  end

  namespace :pg do
    namespace :gis do
      desc 'upgrade postgis'
      task :upgrade => :environment do
        ApplicationRecord.connection.exec_query <<-SQL.strip_sql
          SELECT postgis_extensions_upgrade()
        SQL
      end
    end

    %w(dump restore truncate).each do |name|
      desc "-- [options] #{name.humanize}"
      task name.to_sym => :environment do |t|
        "Db::Pg::#{name.camelize}".constantize.new(self, t).run!
      end
    end

    namespace :dump do
      desc 'rotate dumps'
      task :rotate => :environment do |t|
        Db::Pg::Dump.new(self, t,
          version: true,
          rotate: true,
          split: true,
          md5: true,
          excludes: ExtRails.config.backup_excludes
        ).run!
      end
    end

    desc 'Drop all'
    task :drop_all => :environment do
      sh Sh.psql 'DROP OWNED BY CURRENT_USER', Setting.db_url
    end

    desc 'BRIN summarize'
    task :brin_summarize, [:index] => :environment do |t, args|
      sh Sh.psql "SELECT brin_summarize_new_values('#{args[:index]}')", Setting.db_url
    end

    desc 'ANALYZE database'
    task :analyze, [:table] => :environment do |t, args|
      sh Sh.psql "ANALYZE VERBOSE #{args[:table]}", Setting.db_url
    end

    desc 'VACUUM database'
    task :vacuum, [:table, :analyze, :full] => :environment do |t, args|
      analyze = 'ANALYZE' if flag_on? args, :analyze
      full = 'FULL' if flag_on? args, :full
      sh Sh.psql "VACUUM #{full} #{analyze} VERBOSE #{args[:table]}", Setting.db_url
    end
  end
end
Rake::Task['db:drop'].prerequisites.unshift('db:force_environment_set')
