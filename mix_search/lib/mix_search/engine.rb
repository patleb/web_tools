require 'ext_ruby'
require 'mix_search/configuration'

module MixSearch
  class Engine < ::Rails::Engine
    initializer 'mix_search.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
