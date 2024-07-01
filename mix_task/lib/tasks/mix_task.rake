require_dir __FILE__, 'mix_task'

namespace :task do
  desc 'run "Some.ruby(code)" or filename.rb'
  task :runner, [:code_or_file] => :environment do |t, args|
    if (file = args[:code_or_file])&.end_with? '.rb'
      load file
    elsif (code = args[:code_or_file])&.include? '.'
      eval code, TOPLEVEL_BINDING, __FILE__, __LINE__
    else
      raise "Invalid ruby code or filename"
    end
  end

  desc 'create available tasks (and delete invalid ones)'
  task :delete_or_create_all => :environment do
    Task.delete_or_create_all
  end
end

namespace :try do
  %w(raise_exception sleep sleep_long).each do |name|
    desc "try #{name.tr('_', ' ')}"
    task name.to_sym => :environment do |t|
      "::MixTask::Try::#{name.camelize}".constantize.new(self, t).run!
    end
  end
end
