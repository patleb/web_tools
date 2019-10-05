module MrCore
  module Helpers
    def url_for(path, **params)
      path = path[0] == '/' ? path[1..-1] : path
      params = params.any? ? "?#{params.to_param}" : ''
      "https://#{fetch(:server)}/#{path}#{params}"
    end
  end
end
