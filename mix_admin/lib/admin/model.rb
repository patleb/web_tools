# frozen_string_literal: true

module Admin
  class Model < ActivePresenter::Base
    extend ActiveSupport::Autoload
    include Configurable

    autoload :Association
    autoload :Column
    autoload :Definable, extend: true
    autoload :Searchable, extend: true

    register_class_option :scope do
      klass.all
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
      elsif (parent = klass.module_parent.name.underscore) != 'object'
        t(i18n_key, scope: [i18n_scope, :navigation], default: t(parent, scope: [i18n_scope, :navigation], default: parent.humanize))
      else
        t('admin.misc.root_navigation_label')
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
      MixAdmin.config.simplify_search_string
    end

    register_class_option :record_label_method, instance_reader: true, memoize: true do
      MixAdmin.config.record_label_methods.find{ |method| klass.method_defined? method } || :admin_label
    end

    class << self
      delegate :primary_key, :table_name, to: :klass
    end

    def self.controller(action_hook, &block)
      define_singleton_method action_hook do
        block
      end
    end

    def self.build(attributes = nil)
      if klass.respond_to? :admin_defaults
        attributes = (attributes || {}).reverse_merge(klass.admin_defaults)
      end
      klass.new(attributes)
    end

    def self.index_models
      memoize(Admin::Model, __method__) do
        MixAdmin.config.models_pool.select_map do |model_name|
          next unless (model = model_name.to_const.admin_model).allowed? :index
          model
        end
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
      Admin::Action.allowed?(action) && can?(action, object)
    end

    def self.url_for(action = action_name, **params)
      MixAdmin::Routes.url_for(action: action, model_name: to_param, **params)
    end
    class << self
      alias_method :url, :url_for
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
        associations.each_with_object(allowed: {}, restricted: {}) do |association, memo|
          klass, name = association.klass, association.name
          next if klass.is_a? Array
          next unless (model = klass.admin_model)
          type = index_models.include?(model) ? :allowed : :restricted
          if association.type == :has_many
            count = presenter.associated_count(name, model)
            next unless count > 0
          else
            next unless presenter[name]
            count = 1
          end
          if (memo.dig(type, klass, 0) || 0) < count
            can_destroy = [:restrict_with_error, :restrict_with_exception].exclude? association.options[:dependent]
            memo[type][klass] = if type == :allowed
              url = if (field = associated_field(model))
                model.url_for(:index, q: { field.query_name => presenter[field.column_name] })
              else
                model.url_for(:index)
              end
              [count, url, can_destroy]
            else
              [count, can_destroy]
            end
          end
        end
      end
    end

    def self.associated_field(model)
      memoize(self, __method__, model) do
        model.index.fields.select do |f|
          next unless f.association? && f.queryable?
          associated_model = f.property_model
          [self].concat(supers).any?{ |m| associated_model == m }
        end.sort_by do |f|
          next 2 if f.column_name != primary_key.to_sym
          next 1 if f.property.type == :has_many
          0
        end.first
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
    delegate :klass, to: :model

    def viewable_url(**params)
      model.viewable_url(self, **params)
    end

    def viewable?
      model.viewable?(self)
    end

    def viewable_action
      model.viewable_action(self)
    end

    def allowed_url(action = action_name, **params)
      model.allowed_url(action, self, **params)
    end

    def allowed?(action = action_name)
      model.allowed? action, record
    end

    def url_for(action = action_name, **params)
      model.url_for(action, id: primary_key_value, **params)
    end
    alias_method :url, :url_for

    def primary_key_value
      record.public_send(model.primary_key)
    end

    def associated_count(name, model = nil)
      return self["#{name}_count"] if record.respond_to? "#{name}_count"
      return self[name].count_estimate.to_d if model && model.index.countless?
      self[name].size
    end

    def record_label
      if record.new_record?
        return "#{t('admin.misc.new')} #{model.label}".html_safe
      elsif (label_method = record_label_method) == :admin_label
        return record.admin_label.upcase_first.html_safe
      end
      label = record.try("#{label_method}_changed?") && self["#{label_method}_was"].presence
      label ||= record.public_send(label_method)
      if defined_enums.has_key? label_method.to_s
        label = klass.human_attribute_name("#{label_method}.#{label}", default: label.to_s.humanize)
      end
      label
    end
  end
end
