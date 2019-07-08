class MrSetting::Railtie < Rails::Railtie
  config.before_configuration do
    require 'mr_setting/rails/application'
  end

  rake_tasks do
    load 'tasks/mr_setting.rake'
  end
end
