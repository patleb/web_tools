module ExtRice
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/ext_rice.rake'
    end

    initializer 'ext_rice.require_ext' do
      Rice.require_ext
    end
  end
end
