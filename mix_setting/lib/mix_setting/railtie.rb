module MixSetting
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/mix_setting.rake'
    end
  end
end
