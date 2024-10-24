# frozen_string_literal: true

module Admin
  class Model < ActionView::Delegator
    extend ActiveSupport::Autoload
    include Configurable

    autoload :Association
    autoload :Column
    autoload :Definable, extend: true
    autoload :Searchable, extend: true

    TRASH_ACTIONS = [:trash, :restore]

    register_class_option :scope do
      klass.all
    end

    register_class_option :discardable? do
      klass.discardable?
    end

    register_class_option :listable? do
      klass.listable?
    end

    register_class_option :navigation_weight do
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
        t(navigation_i18n_key, scope: [i18n_scope, :navigation], default: t(:model, scope: [i18n_scope, :navigation]))
      else
        parent = klass.module_parent.name.underscore
        t(i18n_key, scope: [i18n_scope, :navigation], default: t(parent, scope: [i18n_scope, :navigation], default: parent.humanize))
      end.upcase
    end

    register_class_option :navigation_i18n_key do
      nil
    end

    register_class_option :navigation_icon do
      nil
    end

    register_class_option :save_label do
      t(:save, scope: [i18n_scope, :form, i18n_key], default: t('admin.form.save'))
    end

    register_class_option :save_and_new_label do
      t(:save_and_new, scope: [i18n_scope, :form, i18n_key], default: t('admin.form.save_and_new'))
    end

    register_class_option :save_and_edit_label do
      t(:save_and_edit, scope: [i18n_scope, :form, i18n_key], default: t('admin.form.save_and_edit'))
    end

    register_class_option :cancel_label do
      t(:cancel, scope: [i18n_scope, :form, i18n_key], default: t('admin.form.cancel'))
    end

    register_class_option :simplify_search_string? do
      MixAdmin.config.simplify_search_string?
    end

    register_class_option :record_label_method, instance_reader: true, memoize: true do
      MixAdmin.config.record_label_methods.find{ |method| klass.method_defined? method } || :admin_label
    end

    class << self
      delegate :primary_key, :table_name, to: :klass
    end

    def self.build(attributes = nil)
      if klass.respond_to? :admin_defaults
        attributes = (attributes || {}).reverse_merge(klass.admin_defaults)
      end
      klass.new(attributes)
    end

    def self.allowed_models
      MixAdmin.config.models_pool.select_map do |model_name|
        next unless (model = model_name.to_const.admin_model).allowed? :index
        model
      end
    end

    def self.viewable_url(context = self, **params)
      return unless (action = viewable_action(context))
      context.allowed_url(action, **params)
    end

    def self.viewable?(...)
      !!viewable_action(...)
    end

    def self.viewable_action(context = self)
      MixAdmin.config.viewable_actions.find{ |action| context.allowed? action }
    end

    def self.allowed_url(action = action_name, context = self, **params)
      context.url_for(action, **params) if context.allowed? action
    end

    def self.allowed?(action = action_name, object = klass)
      return false if !discardable? && TRASH_ACTIONS.include?(action.to_sym)
      Admin::Action.allowed?(action) && can?(object, action)
    end

    def self.url_for(action, **params)
      MixAdmin::Routes.url_for(action: action, model_name: to_param, **params)
    end

    def self.polymorphic_parents(klass, name)
      ActiveRecord::Base.polymorphic_parents[klass.name][name] || []
    end

    def self.label(*)
      klass.admin_label(*)
    end

    def self.label_plural
      klass.admin_label_plural
    end

    def self.weight
      [navigation_weight, label.downcase]
    end

    def self.i18n_scope
      :adminrecord
    end

    def self.i18n_key
      @i18n_key ||= model_name.underscore
    end

    def self.key
      @key ||= model_name.full_underscore
    end

    def self.model_name
      @model_name ||= name && name.delete_prefix('Admin::').delete_suffix('Presenter')
    end

    def self.klass
      @klass ||= model_name.to_const!
    end

    def self.to_param
      @to_param ||= klass.model_name.admin_param
    end

    def self.param_key
      @param_key ||= klass.model_name.param_key
    end

    def self.associated_counts(presenter)
      Current.with(discardable: false) do
        associations.each_with_object(allowed: [], restricted: []) do |association, memo|
          klass, type = association.klass, :restricted
          if (model = allowed_models.find{ |model| model.klass == klass })
            type = :allowed
          else
            next unless can? klass, :index
          end
          if association.reflection.macro == :has_many
            next unless (count = presenter[association.name].size) > 0
          else
            next unless presenter[association.name]
            count = 1
          end
          memo[type] << [association, count, model].compact
        end
      end
    end

    def self.associations
      associations_hash.values
    end

    def self.associations_hash
      @associations_hash ||= klass.reflect_on_all_associations.each_with_object({}.to_hwia) do |association, hash|
        hash[association.name] = Association.new(association, klass)
      end
    end

    def self.columns
      columns_hash.values
    end

    def self.columns_hash
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
      self.class.url_for(action, id: primary_key_value, **params)
    end

    def primary_key_value
      record.public_send(model.primary_key)
    end

    def discarded?
      record.try(:discarded?)
    end

    def record_label
      label = if record.try("#{record_label_method}_changed?")
        record.public_send("#{record_label_method}_was")
      elsif record.new_record?
        "#{t('admin.misc.new')} #{self.class.label}"
      else
        record.public_send(record_label_method).presence || record.admin_label
      end
      label = "#{label} [#{t('admin.misc.discarded')}]" if discarded?
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
