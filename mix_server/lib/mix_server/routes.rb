# frozen_string_literal: true

module MixServer
  module Routes
    def self.draw(mapper)
      mapper.get '/_server_ip' => 'servers/information#show_ip', as: :server_ip
      mapper.post '/_rescue_js' => 'rescues/javascript#create', as: :rescue_js
    end

    def self.root_path(**params)
      append_query '/', params
    end

    def self.server_ip_path(**params)
      build_path '_server_ip', *params
    end

    def self.rescue_js_path(**params)
      build_path '_rescue_js', **params
    end

    include ExtRails::WithRoutes
  end
end
