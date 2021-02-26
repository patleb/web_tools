require 'ext_ruby'
require 'mix_flash/configuration'

module MixFlash
  class Engine < ::Rails::Engine
    initializer 'mix_flash.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
