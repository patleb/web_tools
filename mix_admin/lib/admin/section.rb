module Admin
  class Section < ActionView::Delegator
    extend ActiveSupport::Autoload
    include Configurable

    class_attribute :weight, instance_writer: false, instance_predicate: false, default: 0

    delegate :model_name, :klass, :group!, :group, :nests, :field!, :field, to: :model

    attr_reader :parent_names
    attr_reader :_no_super, :_exclude_fields, :_fields_of_type

    def self.inherited(subclass)
      super
      if self == Admin::Section || module_parent == Admin::Sections
        subclass.weight = weight + 1
      end
    end

    register_option :include_columns, memoize: true do
      []
    end

    register_option :exclude_columns, memoize: true do
      []
    end

    def after_initialize
      super
      @_no_super ||= {}
      @_exclude_fields ||= []
      @_fields_of_type ||= []
      @parent_names ||= []
      current_name = name
      until current_name == :base
        base_class = Admin::Sections.const_get(current_name.to_s.camelize)
        parent_class = base_class.superclass
        current_name = (parent_class == Admin::Section) ? :base : parent_class.name.demodulize.underscore.to_sym
        @parent_names << current_name
      end
    end

    def parent
      return @parent if defined? @parent
      @parent = (model.section(parent_names.first) unless parent_names.empty?)
    end

    def search_menu
      nil
    end

    def scroll_menu
      div_('.js_scroll_menu.dropdown.dropdown-end') {[
        label_(icon('three-dots-vertical'), tabindex: 0),
        ul_('.dropdown-content', scroll_items, tabindex: 0)
      ]}
    end

    def scroll_items
      (@@scroll_items ||= {})[Current.locale] ||= [
        li_(a_ [icon('arrow-up-circle'), t('admin.misc.top_anchor')], href: '#header', 'data-turbolinks-history': false),
        li_(a_ [icon('arrow-down-circle'), t('admin.misc.bottom_anchor')], href: '#footer', 'data-turbolinks-history': false),
      ]
    end

    def include_fields!(*names, **options, &block)
      names.each{ |f_name| field!(f_name, **options, &block) }
    end

    def include_fields(*names, **options, &block)
      names.each{ |f_name| field(f_name, **options, &block) }
    end

    def exclude_fields!(...)
      @_no_super[:_exclude_fields] = true
      exclude_fields(...)
    end

    def exclude_fields(*names, translated: false, &delete_if)
      if translated
        exclude_fields(*names, &delete_if) if translated == :all
        names = names.map{ |f_name| I18n.available_locales.map{ |locale| "#{f_name}_#{locale}" } }.flatten
        exclude_fields(*names, &delete_if)
      elsif names.empty?
        @_exclude_fields = []
      else
        names.map!(&:to_sym)
        delete_if ||= proc{ |f| names.include? f.name }
        @_exclude_fields << delete_if
      end
    end

    def fields_of_type!(...)
      @_no_super[:_fields_of_type] = true
      fields_of_type(...)
    end

    def fields_of_type(type = nil, &block)
      if type.nil?
        @_fields_of_type = []
      elsif block
        @_fields_of_type << [type, block]
      else
        fields.select{ |_, f| type == f.type }
      end
    end

    def groups
      groups_hash.values
    end

    def groups_hash
      memoize(self, __method__, bindings) do
        _groups.each_with_object({}) do |(name, group), hash|
          group = group.with(bindings)
          hash[name] = group if group.allowed? && group.fields.present?
        end
      end
    end

    def associations
      memoize(self, __method__, bindings) do
        fields.select(&:through).group_by(&:through)
      end
    end

    def fields
      fields_hash.values
    end

    def fields_hash
      memoize(self, __method__, bindings) do
        _fields.each_with_object({}) do |(name, field), hash|
          field = field.with(bindings)
          hash[name] = field if field.allowed?
        end
      end
    end

    def _groups
      @_groups ||= begin
        groups = model.groups[name] || {}
        groups = parent._groups.transform_values{ |v| v.with(section: self) }.merge(groups) if parent
        groups.stable_sort_by{ |(_name, v)| v.weight }.to_h
      end.freeze
    end

    def _fields
      @_fields ||= begin
        fields = model.fields[name] || {}
        fields = parent._fields.transform_values{ |v| v.with(section: self) }.merge(fields) if parent
        fields_of_type = _concat_all(:_fields_of_type)
        exclude_fields = _concat_all(:_exclude_fields)
        fields = fields.reject do |_name, field|
          fields_of_type.each do |(type, block)|
            field.instance_eval(&block) if field.type == type
          end
          exclude_fields.any? do |delete_if|
            field.instance_eval(&delete_if)
          end
        end
        fields.stable_sort_by{ |(_name, v)| v.weight }.to_h
      end.freeze
    end

    def _concat_all(name)
      list = public_send(name)
      unless @super.nil? || @_no_super[name] || (parent._no_super[name] if parent)
        list += @super.public_send(name)
      end
      list += parent.public_send(name) if parent
      list
    end

    private

    def buttons(**actions)
      div_ '.buttons' do
        actions.select_map do |name, label|
          next unless label
          input_ class: name, type: 'submit', name: "_#{name}", value: label, formnovalidate: name == :cancel, data: confirm(name)
        end
      end
    end

    def confirm(name)
      { confirm: (t('admin.misc.confirm') if name == :delete && MixAdmin.config.confirm_delete) }
    end
  end
end
