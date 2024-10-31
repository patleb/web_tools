# frozen_string_literal: true

module Admin
  module Actions
    def self.controller_for(action, &block)
      action.define_singleton_method :controller do
        block
      end
    end
  end

  class Action < ActionController::Delegator
    def self.allowed?(name)
      name = name.to_sym
      if (@@allowed ||= {}).has_key? name
        @@allowed[name]
      else
        @@allowed[name] = !!find_class(name)
      end
    end

    def self.has?(name)
      !!find_class(name)
    end

    def self.find(name, **bindings)
      find_class(name)&.new(**bindings)
    end

    def self.find_class(name)
      name = name.to_sym
      (@@find_class ||= {})[name] ||= all.find{ |action| action.key == name }
    end

    def self.all(type = :all)
      @@all ||= begin
        all = Admin::Actions.constants.each_with_object([]) do |name, all|
          klass = Admin::Actions.const_get(name)
          all << klass if MixAdmin.config.actions.include? klass.key
        end
        all.stable_sort_by(&:weight)
      end
      type == :all ? @@all : @@all.select(&type.to_sym)
    end

    def self.key
      @key ||= name.demodulize.underscore.to_sym
    end

    def self.weight
      0
    end

    # Is the action acting on the root level (Example: /admin/contact)
    def self.root?
      false
    end

    # Is the action on a model scope (Example: /admin/team/export)
    def self.collection?
      false
    end

    # Is the action on an object scope (Example: /admin/team/1/edit)
    def self.member?
      false
    end

    # NOTE You will need to handle params[:ids] in controller
    def self.bulkable?
      false
    end

    def self.navigable?
      true
    end

    def self.searchable_tab?
      searchable?
    end

    def self.searchable?
      false
    end

    # List of methods allowed. Note that you are responsible for correctly handling them in :controller action
    def self.http_methods
      [:get]
    end

    def self.route_fragment
      return '' unless route_fragment?
      route_private? ? "_#{key}" : key.to_s
    end

    def self.route_fragment?
      true
    end

    def self.route_private?
      false
    end

    def self.icon
      raise NotImplementedError
    end

    def self.css_class
      "#{key}_action"
    end

    def self.title(type, object = nil)
      model = object.is_a?(Class) ? object : (presenter = object).model if object
      t(type, scope: [:admin, :actions, key],
        model_label: model&.label,
        model_label_plural: model&.label_plural,
        record_label: presenter&.record_label,
      ).upcase_first
    end

    def self.controller
      action_name = key
      proc do
        define_method action_name do
          render action_name
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

    def trashable?
      false
    end

    def sortable?
      false
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
end
