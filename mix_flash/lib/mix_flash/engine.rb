require 'mix_user'
require 'mix_flash/configuration'

module MixFlash
  class Engine < Rails::Engine
    initializer 'mix_flash.migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_flash.backup' do
      ExtRails.config.temporary_tables << 'lib_flashes'
    end
  end
end
