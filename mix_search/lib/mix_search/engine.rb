require 'ext_rails'
require 'mix_search/configuration'

module MixSearch
  class Engine < Rails::Engine
    initializer 'mix_search.migrations' do |app|
      append_migrations(app)
    end
  end
end
