# frozen_string_literal: true

module MixServer
  module Routes
    def self.draw(mapper)
      mapper.get '/_client_ip' => 'servers/information#show_ip', as: :client_ip
      mapper.post '/_rescue_js' => 'rescues/javascript#create', as: :rescue_js
    end

    def self.root_path(**params)
      append_query '/', params
    end

    def self.client_ip_path(**params)
      build_path '_client_ip', *params
    end

    def self.rescue_js_path(**params)
      build_path '_rescue_js', **params
    end

    include ExtRails::WithRoutes
  end
end
