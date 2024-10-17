# frozen_string_literal: true

module ExtRails
  module WithRoutes
    extend ActiveSupport::Concern

    included do
      raise 'module name must be Routes' unless name.demodulize == 'Routes'
      class << self
        raise 'must have self.root_path defined' unless method_defined? :root_path
      end

      module_parent.define_singleton_method :routes do
        @routes ||= self::Routes.methods.grep(/^(?!root|build)\w+_path$/).each_with_object({}) do |name, routes|
          params = self::Routes.method_keyargs(name)
          params = params.each_with_object({}) do |key, args|
            args[key] = ":#{key}"
          end
          routes[name.to_s.delete_suffix('_path').to_sym] = self::Routes.public_send(name, **params)
        end
      end
    end

    class_methods do
      def method_missing(name, ...)
        if name.end_with?('_url')
          path_method = name.to_s.sub(/_url$/, '_path')
          if respond_to? path_method
            define_singleton_method(name) do |**params|
              url_for(public_send(path_method, **params))
            end
            return public_send(name, ...)
          end
        end
        super
      end

      def respond_to_missing?(name, _include_private = false)
        name.end_with?('_url') && respond_to?(name.to_s.sub(/_url$/, '_path')) || super
      end

      def path?(value)
        if value.start_with? '/'
          value.match? %r{^#{root_path}(/|$|\?)}
        elsif value.start_with? 'http'
          uri = Rack::Utils.parse_root(value)
          uri.hostname == host ? path?(uri.path) : false
        else
          path? "/#{value}"
        end
      end

      def build_path(*fragments, **params)
        path = root_path / fragments.compact_blank.join('/')
        append_query(path, params)
      end

      def append_query(path, params)
        unless (params = params.compact_blank).empty?
          path = "#{path}?#{params.to_query}"
        end
        path
      end

      def base_url
        @@base_url ||= url_for('')
      end

      def root_url(**params)
        url_for(root_path(**params))
      end

      def url_for(path = nil, action: nil, **params)
        [scheme, '://', host, (':' if port), port, path || path_for(action: action, **params)].join
      end

      def path_for(action:, **params)
        public_send("#{action}_path", **params, controller: nil)
      end

      def host
        @@host ||= Rails.application.routes.default_url_options[:host] || raise('routes.default_url_options[:host] must be defined')
      end

      def port
        return @@port if defined? @@port
        @@port = Rails.application.routes.default_url_options[:port]
      end

      def scheme
        @@scheme ||= "http#{'s' if Setting[:server_ssl]}"
      end
    end
  end

  module Routes
    def self.root_path(**params)
      append_query '/', params
    end

    include ExtRails::WithRoutes
  end
end
