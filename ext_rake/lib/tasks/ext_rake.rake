require_rel 'ext_rake'

namespace :ext_rake do
  desc 'setup ExtRake files'
  task :setup do
    # TODO https://gist.github.com/metaskills/8691558
    src, dst = Gem.root('ext_rake').join('lib/tasks/templates'), Rails.root

    mkdir_p dst/'app/tasks'
    cp      src/'app/tasks/application.rake', dst/'app/tasks/application.rake'
    cp      src/'Rakefile', dst/'Rakefile'
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
