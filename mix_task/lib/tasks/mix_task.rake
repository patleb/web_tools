require_rel 'mix_task'

namespace :task do
  desc 'create available tasks (and delete invalid ones)'
  task :create => :environment do
    Task.delete_or_create_all
  end
end

namespace :try do
  %w(raise_exception sleep).each do |name|
    desc "try #{name.tr('_', ' ')}"
    task name.to_sym => :environment do |t|
      "::MixTask::Try::#{name.camelize}".constantize.new(self, t).run!
    end
  end
end
