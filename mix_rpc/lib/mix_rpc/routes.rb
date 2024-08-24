# frozen_string_literal: true

module MixRpc
  module Routes
    def self.draw(mapper)
      mapper.match '/rpc/:id' => 'rpc/functions#call', via: [:get, :post], as: :rpc
    end

    def self.root_path(**params)
      append_query '/rpc', params
    end

    def self.rpc_path(id:, **params)
      build_path id, *params
    end

    include ExtRails::WithRoutes
  end
end
