require_dir __FILE__, 'mix_task'

namespace :task do
  desc 'dump tasks schema'
  task :dump => :environment do
    next unless Rails.env.development?
    File.write(MixTask.config.yml_path, Task.to_yaml)
  end

  desc 'create available tasks (and delete invalid ones)'
  task :delete_or_create_all => :environment do
    Task.delete_or_create_all
  end
end
