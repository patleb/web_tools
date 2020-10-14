# TODO https://www.reddit.com/r/webdev/comments/4bf9hc/how_bad_is_ruby_on_rails_performance_really/
require 'rails_admin/abstract_model'

require 'rails_admin/config/configurable'
require 'rails_admin/config/hideable'
require 'rails_admin/config/proxyable'

require 'rails_admin/config/actions'
require 'rails_admin/config/model'
require 'rails_admin/config/model_proxy'

module RailsAdmin
  # Setup RailsAdmin
  #
  # Given the first argument is a model class, a model class name
  # or an abstract model object proxies to model configuration method.
  #
  # If only a block is passed it is stored to initializer stack to be evaluated
  # on first request in production mode and on each request in development. If
  # initialization has already occured (in other words RailsAdmin.setup has
  # been called) the block will be added to stack and evaluated at once.
  #
  # Otherwise returns RailsAdmin::Config class.
  def self.configure
    yield Config if block_given?
    config
  end

  def self.config
    Config
  end

  def self.model(model, &block)
    Config.model(model_name(model), &block)
  end

  def self.model_name(model)
    case model
    when String, Symbol
      model.to_s
    when AbstractModel
      model.model_name
    when Class
      model.name
    else
      model.is_a?(Config::Model) ? model.abstract_model&.model_name : model.class.name
    end
  end

  def self.actions(scope = :all, abstract_model = nil, object = nil)
    Config::Actions.all(scope, abstract_model: abstract_model, object: object)
  end

  def self.action(custom_key, abstract_model, object = nil)
    Config::Actions.find(custom_key, abstract_model: abstract_model, object: object)
  end

  module Config
    class << self
      # Application title
      attr_accessor :main_app_name

      # Configuration option to specify which models you want to exclude.
      attr_accessor :excluded_models

      # Configuration option to specify a whitelist of models you want to RailsAdmin to work with.
      # The excluded_models list applies against the whitelist as well and further reduces the models
      # RailsAdmin will use.
      # If included_models is left empty ([]), then RailsAdmin will automatically use all the models
      # in your application (less any excluded_models you may have specified).
      attr_accessor :included_models

      # Fields to be hidden in show, create and update views
      attr_accessor :default_hidden_fields

      # Default items per page value used if a model level option has not
      # been configured
      attr_accessor :default_items_per_page
      attr_accessor :default_max_items_per_page

      attr_reader :default_search_operator

      # Configuration option to specify which method names will be searched for
      # to be used as a label for object records. This defaults to [:name, :title]
      attr_accessor :label_methods

      # hide blank fields in show view if true
      attr_accessor :compact_show_view

      # set parent controller
      attr_accessor :parent_controller

      # set settings for `protect_from_forgery` method
      # By default, it raises exception upon invalid CSRF tokens
      attr_accessor :forgery_protection_settings

      # Stores model configuration objects in a hash identified by model's class
      # name.
      attr_reader :models

      # accepts a hash of static links to be shown below the main navigation
      attr_accessor :navigation_static_links

      # use a specific model as root path
      # ex.: config.root_model_name = 'module_name-model_name'
      attr_accessor :root_model_name

      attr_accessor :default_truncate_length
      attr_accessor :chart_max_rows
      attr_accessor :export_max_rows

      attr_accessor :katex_version

      def default_search_operator=(operator)
        if %w(default like starts_with ends_with is =).include? operator
          @default_search_operator = operator
        else
          raise(ArgumentError.new("Search operator '#{operator}' not supported"))
        end
      end

      # pool of all found model names from the whole application
      def models_pool
        SortedSet.new(viable_models - expand_models(excluded_models))
      end

      # Loads a model configuration instance from the models or registers
      # a new one if one is yet to be added.
      #
      # First argument can be an instance of requested model, its class object,
      # its class name as a string or symbol or a RailsAdmin::AbstractModel
      # instance.
      #
      # If a block is given it is evaluated in the context of configuration instance.
      #
      # Returns given model's configuration
      def model(name, &block)
        @models[name] ||= ModelProxy.new(name)
        @models[name].add_deferred_block(&block) if block
        @models[name]
      end

      def default_hidden_fields=(fields)
        if fields.is_a?(Array)
          @default_hidden_fields = {}
          @default_hidden_fields[:edit] = fields
          @default_hidden_fields[:show] = fields
        else
          @default_hidden_fields = fields
        end
      end

      # Returns action configuration object
      def actions(&block)
        Actions.init_actions!
        Actions.instance_eval(&block) if block
      end

      # Reset all configurations to defaults.
      def reset
        @compact_show_view = true
        @default_hidden_fields = {}
        @default_hidden_fields[:base] = [:json_data, :deleted_at, :position]
        @default_hidden_fields[:show] = [:id, :created_at, :updated_at]
        @default_hidden_fields[:edit] = @default_hidden_fields[:show] + [:creator_id, :updater_id, :creator, :updater]
        @default_items_per_page = 25
        @default_max_items_per_page = 100
        @default_search_operator = 'default'
        @excluded_models = []
        @included_models = []
        @label_methods = [:name, :title]
        @main_app_name = proc{ Rails.application.title }
        @models = {}
        @navigation_static_links = {}
        @parent_controller = 'TemplatesController'
        @forgery_protection_settings = { with: :exception, prepend: true }
        @root_model_name = defined?(MixUser) ? 'User' : nil
        @default_truncate_length = 50
        @chart_max_rows = 750_000
        @export_max_rows = 750_000
        @katex_version = '0.12.0'
        Actions.reset
      end

      # Reset all models configuration
      # Used to clear all configurations when reloading code in development.
      def reset_all_models
        @models = {}
      end

      # Get all models that are configured as visible.
      def visible_models
        RailsAdmin::AbstractModel.all.each_with_object([]) do |(_model_name, abstract_model), visible_models|
          next unless RailsAdmin.action(:index, abstract_model)
          visible_models << abstract_model.model
        end
      end

      private

      def viable_models
        expand_models(included_models).presence || ActiveRecord::Base.viable_models
      end

      # TODO https://github.com/baweaver/globs
      def expand_models(list)
        list.flat_map do |name|
          name = name.to_s
          if name.include? '%'
            name = "^#{name}" if name.start_with? '%'
            name = "#{name}$" if name.end_with? '%'
            regex = /#{name.gsub('%', '.*')}/
            ActiveRecord::Base.viable_models.select(&:match?.with(regex))
          else
            name
          end
        end
      end
    end

    # Set default values for configuration options on load
    reset
  end
end
