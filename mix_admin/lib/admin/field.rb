module Admin
  class Field < ActionView::Delegator
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :AsArray
      autoload :AsAssociation
      autoload :AsRange
    end
    include Configurable

    attr_accessor :weight, :group
    attr_writer :editable

    delegate :klass, to: :model
    delegate :type, to: :class

    def self.find_class(section, property)
      @@find_class ||= Admin::Fields.constants.sort.reverse.select_map do |name|
        next if name.end_with? 'Array'
        klass = Admin::Fields.const_get(name)
        klass if klass.singleton_class.method_defined? :has?
      end
      klass = @@find_class.find{ |klass| klass.has? section, property }
      property.array? ? Admin::Fields.const_get("#{klass.name.demodulize}Array") : klass
    end

    def self.type
      @type ||= begin
        base_class = superclass
        base_class = base_class.superclass while base_class.module_parent != Admin::Fields
        base_class.name.demodulize.underscore.to_sym
      end
    end

    register_option :allowed? do
      allowed_field?
    end

    register_option :allowed_methods do
      [method_name]
    end

    register_option :readonly? do
      !editable?
    end

    register_option :required? do
      next false if property.nil? || action.show?
      next true  if property.true?(:required?) && property.try(:default).nil?
      ([name] + children_names).uniq.any? do |column_name|
        klass.validators_on(column_name).any? do |v|
          next if     (v.options[:allow_nil] || v.options[:allow_blank])
          next unless [:presence, :numericality, :attachment_presence].include?(v.kind)
          next unless (v.options[:on] == required_context || v.options[:on].blank?)
          (v.options[:if].blank? && v.options[:unless].blank?)
        end
      end
    end

    register_option :label, memoize: :locale do
      klass.human_attribute_name(name).upcase_first
    end

    register_option :pretty_value do
      format_value(value).presence || pretty_blank
    end

    register_option :pretty_blank, memoize: :locale do
      '-'.html_safe
    end

    # NOTE Current.view isn't available
    register_option :export_value do
      format_export(value)
    end

    register_option :index_value do
      if primary_key?
        primary_key_link
      else
        pretty_value
      end
    end

    register_option :sortable?, memoize: true do
      !method? || method_searchable? || children_names.first || false
    end

    register_option :sort_reverse?, memoize: true do
      false
    end

    register_option :queryable?, memoize: true do
      !method? || method_searchable? || children_names.first || false
    end

    register_option :method_searchable?, memoize: true do
      false
    end

    # NOTE first one is used for sort/search
    register_option :children_names, memoize: true do
      []
    end

    register_option :input do
      input_ type: input_type, name: input_name, class: input_css_class, **input_attributes
    end

    register_option :input_attributes do
      default_input_attributes
    end

    register_option :default_value do
      property.try(:default)
    end

    register_option :css_class do
      "#{name}_field #{type_css_class}#{' readonly' if readonly?}"
    end

    register_option :help do
      readonly ? false : I18n.t(name, scope: [model.i18n_scope, :help, model.i18n_key], default: default_help)
    end

    def parent
      return @parent if defined? @parent
      parent = section.parent
      @parent = parent && parent.weight < section_was.weight ? parent.fields_hash[name] : nil
    end

    def required_context
      return :nil unless presenter
      presenter[:persisted?] ? :update : :create
    end

    def property
      return @property if defined? @property
      @property = model.property(name)
    end

    def allowed_field?
      return false if primary_key? && action.new?
      MixAdmin.config.denied_fields.exclude? name
    end

    def editable?
      return @editable if defined? @editable
      return false if action.show?
      return false if MixAdmin.config.readonly_fields.include? name
      (property && presenter[:new_record?]) || !property.nil_or_true?(:readonly?)
    end

    def primary_key?
      return @primary_key if defined? @primary_key
      @primary_key = model.primary_key.to_sym == name
    end

    def type_css_class
      "#{type}_type#{' array_type' if array?}#{' association_type' if association?}"
    end

    def array?
      is_a? Field::AsArray
    end

    def association?
      is_a? Field::AsAssociation
    end

    # NOTE overrides params[name]
    def parse_input!(params)
    end

    def parse_search(value)
      value
    end

    def parse_value(value)
      value
    end

    def format_value(value)
      value
    end

    def format_input(value)
      value
    end

    def format_export(value)
      value
    end

    def value
      presenter[name]
    end

    def inverse_of
      nil
    end

    def nested_options
      false
    end

    def method?
      property.nil_or_true?(:virtual?)
    end

    def method_name
      name
    end

    def pretty_input
      return pretty_value if readonly?
      return input unless label
      return [input, p_('.text-error', errors.to_sentence)] if errors.present?
      input
    end

    def input_type
      :text
    end

    def input_name
      method_name
    end

    def input_value
      format_input((presenter[:new_record?] && value.nil?) ? default_value : value)
    end

    def input_css_class
      classes = Set.new(['input'])
      classes << (errors.present? ? 'input-error' : 'input-bordered')
      classes
    end

    def default_input_attributes
      { required: required?, value: input_value }
    end

    def default_help
      false
    end

    def pretty_label
      text = [label]
      text, title = text << '*', I18n.t('admin.form.required') if required?
      h_(
        label_(text, title: title),
        icon('info-circle.tooltip', data: { tip: help }, if: help.present?),
      )
    end

    def search_type
      :string
    end

    def errors
      ([name] + children_names).uniq.map do |column_name|
        presenter[:errors][column_name]
      end.uniq.flatten
    end

    def primary_key_link(label = pretty_value)
      url = !presenter.discarded? && presenter.viewable_url
      url ? a_('.link.text-primary', label, href: url) : label
    end

    def sort_link
      return unless sortable?
      url, active, reverse = sort_options
      reverse = !active && reverse || active && !reverse
      title = reverse ? I18n.t('admin.misc.desc') : I18n.t('admin.misc.asc')
      h_(ascii(:space),
        a_('.sort_link', href: url, class: ('sort_active' if active), title: title) {[
          ascii("triangle_#{reverse ? 'down' : 'up'}"),
          ascii(:space)
        ]}
      )
    end

    def sort_options
      return unless sortable?
      sort, reverse = params[:s], params[:r]
      if sort == name.to_s || sort.blank? && section.sort_by == name
        if reverse.present? && reverse.to_b?
          reverse = !reverse.to_b
        else
          reverse = !sort_reverse?
        end
        active = true
      else
        reverse = sort_reverse?
      end
      [model.url_for(:index, q: params[:q].presence, f: params[:f].presence, s: name, r: reverse), active, reverse]
    end

    def sort_column
      @sort_column ||= case (column_name = sortable)
        when true           then "#{model.table_name}.#{name}"
        when false          then "#{model.table_name}.#{section.sort_by}"
        when String, Symbol then column_name.to_s.include?('.') ? column_name : "#{model.table_name}.#{column_name}"
        when Hash           then column_name.first.join('.')
        else                     "#{associated_model.table_name}.#{column_name}" if association?
        end || raise("invalid :sortable column, can't be nil")
    end

    def query_column
      @query_column ||= case (column_name = queryable)
        when true           then "#{model.table_name}.#{name}"
        when String, Symbol then column_name.to_s.include?('.') ? column_name : "#{model.table_name}.#{column_name}"
        when Hash           then column_name.first.join('.') # { table_name: column_name }
        else                     "#{associated_model.table_name}.#{column_name}" if association?
        end
    end

    def query_fields
      @query_fields ||= case queryable
        when true  then { model.to_param => { name => self } }
        when false then {}
        else
          Array.wrap(queryable).each_with_object({}) do |field_name, hash|
            case field_name
            when String, Symbol
              if association?
                model_param, fields_hash = associated_model.to_param, associated_model.section(:index).fields_hash
              else
                model_param, fields_hash = model.to_param, section.fields_hash
              end
              field_name = field_name.to_sym
              field = fields_hash[field_name]
              (hash[model_param] ||= {})[field_name] ||= field if field
            when Hash # { ModelName => [:field_name] }
              model, field_names = field_name.first
              model = model.to_const! if model.is_a? String
              model, field_names = model.admin_model, Array.wrap(field_names).map(&:to_sym)
              fields_hash = model.section(:index).fields_hash.slice(*field_names)
              (hash[model.to_param] ||= {}).reverse_merge!(fields_hash) if fields_hash.present?
            else
              raise "invalid :queryable field: [#{field_name}]"
            end
          end
        end
    end
  end
end
