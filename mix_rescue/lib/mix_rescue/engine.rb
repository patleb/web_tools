require 'mix_rescue/configuration'

autoload :Notice, 'mix_rescue/notice'

module MixRescue
  class Engine < ::Rails::Engine
    config.before_initialize do
      autoload_models_if_admin('Rescue')
    end

    initializer 'mix_rescue.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
