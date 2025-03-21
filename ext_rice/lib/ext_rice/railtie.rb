module ExtRice
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/ext_rice.rake'
    end

    config.before_initialize do |app|
      ActiveSupport::Dependencies.autoload_paths.delete("#{app.root}/app/rice")
    end

    initializer 'ext_rice.require_ext' do
      require "numo/narray" if Rice.require_numo?
      Rice.require_ext
    end
  end
end
