require 'ext_ruby'
require 'user_agent_parser'
require 'countries'
require 'mix_geo/configuration'
require 'mix_geo/user_agent_parser/user_agent'
require 'mix_geo/countries/country'

module MixGeo
  class Engine < ::Rails::Engine
    initializer 'mix_geo.append_migrations' do |app|
      append_migrations(app)
    end

    ActiveSupport.on_load(:active_record) do
      MixSearch.config.available_types.merge!(
        'GeoState' => 10
      )
    end
  end
end
