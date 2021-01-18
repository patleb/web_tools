require_rel 'mix_task'

namespace :mix_task do
  desc 'setup MixTask files'
  task :setup do
    # TODO https://gist.github.com/metaskills/8691558
    src, dst = Gem.root('mix_task').join('lib/tasks/templates'), Rails.root

    mkdir_p dst/'app/tasks'
    remove  dst/'app/tasks/.keep' rescue nil
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

namespace :try do
  %w(raise_exception sleep).each do |name|
    desc "-- [options] Try #{name.humanize}"
    task name.to_sym => :environment do |t|
      "::MixTask::Try::#{name.camelize}".constantize.new(self, t).run!
    end
  end
end
