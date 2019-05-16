module ExtCapistrano
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/ext_capistrano.rake'
    end
  end
end
