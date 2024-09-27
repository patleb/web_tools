module Admin
  class Model < ActionView::Delegator
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Association
      autoload :Column
      autoload :Definable
      autoload :Searchable
    end
    include Configurable
    extend Definable
    extend Searchable

    TRASH_ACTIONS = Set.new([:trash, :restore])

    register_class_option :scope do
      klass.all
    end

    register_class_option :discardable?, memoize: true do
      klass.discardable?
    end

    register_class_option :listable?, memoize: true do
      klass.listable?
    end

    register_class_option :label, memoize: :locale do
      pretty_name
    end

    register_class_option :label_plural, memoize: :locale do
      if label != (label_plural = pretty_name(count: Float::INFINITY, default: label))
        label_plural
      else
        label.pluralize(Current.locale)
      end
    end

    register_class_option :navigation_weight, memoize: true do
      0
    end

    register_class_option :navigation_parent, memoize: true do
      parent_class = klass.superclass
      if parent_class.respond_to? :extended_record_base_class
        parent_class.extended_record_base_class.to_s
      elsif parent_class.abstract_class?
        nil
      else
        parent_class.to_s
      end
    end

    register_class_option :navigation_label, memoize: :locale do
      if navigation_i18n_key
        I18n.t(navigation_i18n_key, scope: [i18n_scope, :navigation], default:
          I18n.t(:model, scope: [i18n_scope, :navigation])
        )
      else
        I18n.t(i18n_key, scope: [i18n_scope, :navigation], default:
          I18n.t((parent_module = klass.module_parent.name.underscore), scope: [i18n_scope, :navigation], default:
            parent_module.humanize
          )
        )
      end.upcase
    end

    register_class_option :navigation_i18n_key, memoize: true do
      nil
    end

    register_class_option :navigation_icon, memoize: true do
      nil
    end

    register_class_option :save_label, memoize: :locale do
      I18n.t(:save, scope: [i18n_scope, :form, i18n_key], default: I18n.t('admin.form.save'))
    end

    register_class_option :save_and_add_another_label, memoize: :locale do
      I18n.t(:save_and_add_another, scope: [i18n_scope, :form, i18n_key], default: I18n.t('admin.form.save_and_add_another'))
    end

    register_class_option :save_and_edit_label, memoize: :locale do
      I18n.t(:save_and_edit, scope: [i18n_scope, :form, i18n_key], default: I18n.t('admin.form.save_and_edit'))
    end

    register_class_option :cancel_label, memoize: :locale do
      I18n.t(:cancel, scope: [i18n_scope, :form, i18n_key], default: I18n.t('admin.form.cancel'))
    end

    register_class_option :simplified_search_string?, memoize: true do
      MixAdmin.config.simplified_search_string?
    end

    register_class_option :record_label_method, instance_reader: true, memoize: true do
      MixAdmin.config.record_label_methods.find{ |method| klass.method_defined? method } || :admin_label
    end

    class << self
      delegate :primary_key, :table_name, to: :klass

      def build(params)
        if klass.respond_to? :admin_defaults
          params = params.reverse_merge(klass.admin_defaults)
        end
        klass.new(params)
      end

      def allowed_models
        MixAdmin.config.models_pool.select_map do |model_name|
          next unless (model = model_name.to_const.admin_model).allowed? :index
          model
        end
      end

      def viewable_url(context = self, **params)
        return unless (action = viewable_action(context))
        context.allowed_url(action, **params)
      end

      def viewable?(...)
        !!viewable_action(...)
      end

      def viewable_action(context = self)
        MixAdmin.config.viewable_actions.find{ |action| context.allowed? action }
      end

      def allowed_url(action = action_name, context = self, **params)
        context.url_for(action, **params) if context.allowed? action
      end

      def allowed?(action = action_name, object = klass)
        Admin::Action.allowed?(action) && can?(object, action)
      end

      def url_for(action, **params)
        MixAdmin::Routes.url_for(action: action, model_name: to_param, **params)
      end

      def polymorphic_parents(klass, name)
        ActiveRecord::Base.polymorphic_parents[klass.name][name] || []
      end

      def pluralize(count)
        count == 1 ? label : label_plural
      end

      def weight
        "#{(navigation_weight + 32768).to_s}#{label.downcase}"
      end

      def i18n_scope
        :adminrecord
      end

      def i18n_key
        @i18n_key ||= model_name.underscore
      end

      def key
        @key ||= model_name.full_underscore
      end

      def model_name
        @model_name ||= name && name.delete_prefix('Admin::').delete_suffix('Presenter')
      end

      def klass
        @klass ||= model_name.to_const!
      end

      def to_param
        @to_param ||= klass.model_name.admin_param
      end

      def param_key
        @param_key ||= klass.model_name.admin_param_key
      end

      def pretty_name(...)
        klass.model_name.human(...)
      end

      def map_associations(presenter)
        associations.map do |association|
          presenters = presenter[association.name].map(&:admin_presenter).select(&:allowed?)
          yield(association, Array.wrap(presenters))
        end
      end

      def associations
        associations_hash.values
      end

      def associations_hash
        @associations_hash ||= klass.reflect_on_all_associations.each_with_object({}.to_hwia) do |association, hash|
          hash[association.name] = Association.new(association, klass)
        end
      end

      def columns
        columns_hash.values
      end

      def columns_hash
        @columns_hash ||= {
          columns_hash: false,
          attribute_types: true,
          virtual_columns_hash: true
        }.each_with_object({}.to_hwia) do |(columns, virtual), hash|
          next unless klass.respond_to? columns
          klass.public_send(columns).each do |name, column|
            hash[name] ||= Column.new(column, klass, name, virtual)
          end
        end
      end
    end

    alias_method :model, :class

    def viewable_url(**params)
      self.class.viewable_url(self, **params)
    end

    def viewable?
      self.class.viewable?(self)
    end

    def viewable_action
      self.class.viewable_action(self)
    end

    def allowed_url(action = action_name, **params)
      self.class.allowed_url(action, self, **params)
    end

    def allowed?(action = action_name)
      return false if discarded? && TRASH_ACTIONS.exclude?(action.to_sym)
      self.class.allowed? action, record
    end

    def url_for(action, **params)
      self.class.url_for(action, id: record.public_send(model.primary_key), **params)
    end

    def discarded?
      record.try(:discarded?)
    end

    def record_label
      label = if record.try("#{record_label_method}_changed?")
        record.public_send("#{record_label_method}_was")
      elsif record.new_record?
        "#{I18n.t('admin.misc.new')} #{self.class.pretty_name}"
      else
        record.public_send(record_label_method)
      end
      label = "#{label} [#{I18n.t('admin.misc.discarded')}]" if discarded?
      label.upcase_first
    end

    def record
      @_locals[:record]
    end

    def [](name)
      record.public_send(name)
    end

    def method_missing(name, ...)
      if record.respond_to? name
        record.public_send(name, ...)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      record.respond_to?(name, include_private) || super
    end
  end
end
