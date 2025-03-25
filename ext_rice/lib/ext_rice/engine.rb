module ExtRice
  class Engine < Rails::Engine
    config.before_initialize do |app|
      ActiveSupport::Dependencies.autoload_paths.delete("#{app.root}/app/rice")
    end

    initializer 'ext_rice.require_ext' do
      Rice.require_ext unless Rails.env.test?
    end
  end
end
