require_rel 'ext_rake'

namespace :rails do
  desc 'setup Rakefile'
  task :setup_rakefile do
    before = 'Rails.application.load_tasks'
    after = "load 'app/tasks/application.rake'\n\nRails.application.all_rake_tasks"
    Pathname.new('Rakefile').write(Pathname.new('Rakefile').read.sub(before, after))
  end

  desc 'truncate log'
  task :truncate_log, [:suffix] => :environment do |t, args|
    if (suffix = args[:suffix]).present?
      sh "truncate -s 0 log/#{Rails.env}.log#{suffix}"
    else
      sh "truncate -s 0 log/#{Rails.env}.log"
    end
  end
end

namespace :test do
  %w(raise_exception send_mail sleep).each do |name|
    desc "-- [options] Test #{name.humanize}"
    task name.to_sym => :environment do |t|
      "::ExtRake::Test::#{name.camelize}".constantize.new(self, t).run
    end
  end
end
