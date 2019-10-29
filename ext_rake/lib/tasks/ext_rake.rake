require_rel 'ext_rake'

namespace :ext_rake do
  desc 'setup app/libraries/.keep, app/tasks/application.rake, lib/.keep and Rakefile'
  task :setup do
    # TODO https://gist.github.com/metaskills/8691558
    src, dst = Gem.root('ext_rake').join('lib/tasks/templates'), Rails.root
    keep    dst.join('app/libraries')
    mkdir_p dst.join('app/tasks')
    cp      src.join('app/tasks/application.rake'), dst.join('app/tasks/application.rake')
    rmtree  dst.join('lib')
    keep    dst.join('lib')
    cp      src.join('Rakefile'), dst.join('Rakefile')
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
      "::ExtRake::Test::#{name.camelize}".constantize.new(self, t).run!
    end
  end
end
