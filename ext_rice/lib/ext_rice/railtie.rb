module ExtRice
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/ext_rice.rake'
    end
  end
end
