require_rel 'ext_rake'

namespace :ext_rake do
  desc 'setup Rakefile, app/libraries/.keep, app/tasks/application.rake and lib/.keep'
  task :setup do
    before = 'Rails.application.load_tasks'
    after = "load 'app/tasks/application.rake'\n\nRails.application.all_rake_tasks"
    Pathname.new('Rakefile').write(Pathname.new('Rakefile').read.sub(before, after))

    base = Gem.root('ext_rake').join('lib/tasks/templates')

    mkdir_p Rails.root.join('app/libraries')
    touch   Rails.root.join('app/libraries/.keep')
    mkdir_p Rails.root.join('app/tasks')
    cp      base.join('app/tasks/application.rake'), Rails.root.join('app/tasks/application.rake')
    rmtree  Rails.root.join('lib')
    mkdir   Rails.root.join('lib')
    touch   Rails.root.join('lib/.keep')
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
