require "mix_global/configuration"

module MixGlobal
  class Engine < ::Rails::Engine
    config.before_initialize do
      unless defined? MixAdmin
        Rails.autoloaders.main.ignore("#{root}/app/models/global_admin.rb")
      end
    end

    initializer 'mix_global.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
