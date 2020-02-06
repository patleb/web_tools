module MixSetting
  class Railtie < Rails::Railtie
    config.before_configuration do
      require 'mix_setting/rails/application'
    end

    rake_tasks do
      load 'tasks/mix_setting.rake'
    end
  end
end
