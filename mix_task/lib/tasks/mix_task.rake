require_rel 'mix_task'

namespace :task do
  desc 'create available tasks'
  task :create => :environment do
    MixTask.config.available_names.each do |name, _|
      Task.find_or_create_by! name: name
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
