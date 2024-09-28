module Admin
  def self.base_controller_for(action, &block)
    action.define_singleton_method :base_controller do
      block
    end
  end

  module Actions
    def self.controller_for(action, &block)
      action.define_singleton_method :controller do
        block
      end
    end
  end

  class Action < ActionController::Delegator
    class << self
      def allowed?(name)
        name = name.to_sym
        if (@@allowed ||= {}).has_key? name
          @@allowed[name]
        else
          @@allowed[name] = !!find_class(name)
        end
      end

      def has?(name)
        !!find_class(name)
      end

      def find(name, **bindings)
        find_class(name)&.new(**bindings)
      end

      def find_class(name)
        name = name.to_sym
        (@@find_class ||= {})[name] ||= all.find{ |action| action.key == name }
      end

      def all(type = :all)
        @@all ||= begin
          all = Admin::Actions.constants.each_with_object([]) do |name, all|
            klass = Admin::Actions.const_get(name)
            all << klass if MixAdmin.config.actions.include? klass.key
          end
          all.stable_sort_by(&:weight)
        end
        type == :all ? @@all : @@all.select(&type.to_sym)
      end

      def key
        @key ||= name.demodulize.underscore.to_sym
      end

      def weight
        0
      end

      # TODO :new (in process mem), :show (in DB), :edit[GET] (in DB), :export (in process mem partially --> except counter)
      def cacheable?
        false
      end

      # Is the action acting on the root level (Example: /admin/contact)
      def root?
        false
      end

      # Is the action on a model scope (Example: /admin/team/export)
      def collection?
        false
      end

      # Is the action on an object scope (Example: /admin/team/1/edit)
      def member?
        false
      end

      # NOTE You will need to handle params[:ids] in controller
      def bulkable?
        false
      end

      def navigable?
        true
      end

      def searchable_tab?
        searchable?
      end

      def searchable?
        false
      end

      def bulk_menu?
        bulkable?
      end

      def inline_menu?
        member?
      end

      # List of methods allowed. Note that you are responsible for correctly handling them in :controller action
      def http_methods
        [:get]
      end

      def route_fragment?
        true
      end

      def icon
        raise NotImplementedError
      end

      def css_class
        "#{key}_action"
      end

      def title(type, object = nil)
        model = object.is_a?(Class) ? object : (presenter = object).model if object
        I18n.t(type, scope: [:admin, :actions, key],
          model_label: model&.label,
          model_label_plural: model&.label_plural,
          record_label: presenter&.record_label,
        ).upcase_first
      end

      def controller
        action_name = key
        proc do
          define_method action_name do
            render action_name
          end
        end
      end
    end

    delegate :root?, :collection?, :member?, :bulkable?, :http_methods, :title, to: :class

    def name
      self.class.key
    end

    def section_name
      name
    end

    def model?
      !root?
    end

    def presenters?
      !root?
    end

    def trash?
      false
    end

    def sort?
      false
    end

    def back_on_cancel?
      true
    end

    def method_missing(name, ...)
      if name.end_with?('?') && (key = name[0..-2].to_sym) && self.class.has?(key)
        self.class.send(:define_method, name) do
          self.name == key
        end
        public_send(name)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.end_with?('?') && self.class.has?(name[0..-2].to_sym) || super
    end
  end

  base_controller_for Action do
    def sanitize_params!
      return unless (target_params = params[@model.param_key]).present?
      fields = @section.fields
      allowed_methods = fields.flat_map(&:allowed_methods).uniq
      target_params.slice! *allowed_methods
      target_params.permit!
      fields.each{ |field| field.parse_input! target_params }
      target_params
    end
  end
end
