module ExtMinitest
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/ext_minitest.rake'
    end
  end
end
