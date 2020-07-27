# TODO https://travisofthenorth.com/blog/2017/12/27/rails-urlhelpers
# TODO https://github.com/thedarkone/rails-dev-boost
module RailsAdmin
  module Routes
    INVALID_FRAGMENTS = [nil, '', '/'].freeze

    def url_for(action:, controller: nil, **params)
      path = send "#{action}_path", **params
      unless (@host ||= Rails.application.routes.default_url_options[:host])
        raise "routes.default_url_options[:host] must be defined"
      end
      @port = Rails.application.routes.default_url_options[:port] unless defined? @port
      @protocol ||= "http#{'s' if Rails.application.config.force_ssl}://"
      [@protocol, @host, (':' if @port), @port, path].join
    end

    def path_for(*fragments, **params)
      path = root_path == '/' ? '' : root_path
      path = [path].concat(fragments.reject{ |fragment| INVALID_FRAGMENTS.include? fragment }).join('/')
      if (params = params.compact).any?
        path << "?" << params.to_param
      end
      path
    end

    def add_route(type, action_name = nil, route_fragment = nil)
      case type
      when :base
        define_singleton_method :root_path do |**params|
          @root_path ||= begin
            path = RailsAdmin::Engine.routes.url_helpers.send(:root_path, params)
            path.delete_suffix('/').presence || '/'
          end
        end
      when :root
        define_singleton_method "#{action_name}_path" do |**params|
          path_for route_fragment, **params
        end
      when :collection
        define_singleton_method "#{action_name}_path" do |model_name:, **params|
          path_for model_name, route_fragment, **params
        end
      when :member
        define_singleton_method "#{action_name}_path" do |model_name:, id:, **params|
          path_for model_name, id, route_fragment, **params
        end
      else
        raise "type [:base, :root, :collection, :member] must be specified"
      end
    end

    def js_routes
      @js_routes ||= methods.grep(/_path$/).each_with_object({}) do |name, routes|
        params = method_keyargs(name)
        params = params.each_with_object({}) do |key, args|
          args[key] = "__#{key.to_s.upcase}__"
        end
        routes[name.to_s.sub(/_path$/, '').to_sym] = send(name, **params)
      end
    end
  end
end
