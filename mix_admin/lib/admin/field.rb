module Admin
  class Field < ActionView::Delegator
    extend ActiveSupport::Autoload
    include Configurable

    attr_accessor :weight, :group, :through, :as
    attr_writer :array, :editable, :index_link

    delegate :klass, to: :model
    delegate :type, to: :class
    delegate :association?, to: :property, allow_nil: true

    def self.find_class(section, property)
      @@find_class ||= Admin::Fields.constants.except(:Association).sort.reverse.select_map do |name|
        klass = Admin::Fields.const_get(name)
        klass if klass.singleton_class.method_defined? :has?
      end
      @@find_class.find{ |klass| klass.has? section, property }
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

    register_option :readonly do
      !editable?
    end

    register_option :required? do
      next false if property.nil?
      next true  if property.true?(:required?) && property.try(:default).nil?
      ([property_name] + association_names).uniq.any? do |name|
        klass.validators_on(name).any? do |v|
          next if     (v.options[:allow_nil] || v.options[:allow_blank])
          next unless [:presence, :numericality, :attachment_presence].include?(v.kind)
          next unless (v.options[:on] == required_context || v.options[:on].blank?)
          (v.options[:if].blank? && v.options[:unless].blank?)
        end
      end
    end

    register_option :label do
      input_label
    end

    register_option :pretty_value do
      array? ? format_array(value) : format_value(value)
    end

    register_option :pretty_show do
      pretty_value
    end

    register_option :pretty_index do
      next pretty_value if value? 'pretty_value'
      array? ? format_array_index(value) : format_index(value)
    end

    register_option :pretty_blank do
      span_ '.blank', '-'
    end

    # NOTE Current.view isn't available
    register_option :pretty_export do
      array? ? format_array_export(value) : format_export(value)
    end

    register_option :array_separator do
      false
    end

    register_option :array_bullet do
      false
    end

    register_option :array_export_separator do
      ' '
    end

    register_option :sortable? do
      queryable
    end

    register_option :sort_reverse? do
      false
    end

    register_option :queryable? do
      !method? || method_queryable?
    end

    register_option :method_queryable? do
      false
    end

    register_option :full_query_name? do
      full_query_column
    end

    register_option :full_query_column? do
      MixAdmin.config.full_query_column || section.column_name_counts[column_name].to_i > 1
    end

    register_option :input do
      input_control
    end

    register_option :input_attributes do
      default_input_attributes
    end

    register_option :default_value do
      property.try(:default)
    end

    register_option :truncated? do
      false
    end

    register_option :css_class do
      type_css_class
    end

    register_option :help do
      next false if readonly?
      t(column_name, scope: [property_model.i18n_scope, :help, property_model.i18n_key], default: default_help)
    end

    def parent
      return @parent if defined? @parent
      parent = section.parent
      @parent = parent && parent.weight < section_was.weight ? parent.fields_hash[name] : nil
    end

    def required_context
      return :nil unless presenter
      presenter.persisted? ? :update : :create
    end

    def property
      return @property if defined? @property
      @property = model.property(property_name)
    end

    def allowed_field?
      return false if primary_key? && action.new?
      MixAdmin.config.denied_fields.exclude? column_name
    end

    def readonly?
      action.show? || readonly
    end

    def array?
      return @array if defined? @array
      property&.array?
    end

    def editable?
      return @editable if defined? @editable
      return false if array?
      return false if presenter.readonly?
      return false if method? || primary_key? || MixAdmin.config.readonly_fields.include?(column_name)
      action.new? || property.false?(:readonly?)
    end

    def primary_key?
      return @primary_key if defined? @primary_key
      @primary_key = model.primary_key.to_sym == name
    end

    def type_css_class
      "#{name}_field #{type}_type#{' array_type' if array?}#{' truncated' if truncated?}"
    end

    def pretty_label
      text = [label]
      text, title = text << '*', t('admin.form.required') if !action.show? && required? && !readonly?
      h_(
        label_(text, title: title),
        _icon('info-circle.tooltip', data: { tip: help }, if: !action.show? && help.present?),
      )
    end

    def pretty_input
      return pretty_show.presence || pretty_blank if readonly?
      return input unless label
      return [input, p_('.text-error', errors.to_sentence)] if errors.present?
      input
    end

    # NOTE overrides params[column_name]
    def parse_input!(params)
    end

    def parse_input(value)
      value
    end

    def parse_search(value)
      value
    end

    def format_array(value)
      return pretty_blank unless value.present?
      array = value.map.with_index do |v, i|
        (block_given? ? yield(v, i) : format_value(v)).presence || pretty_blank
      end
      if array_separator
        separator = ascii(:space)
        separator += array_separator unless array_separator == true
        if array_bullet
          array = array.join(separator + array_bullet).html_safe
          array = array_bullet + array if array.present?
        else
          array = array.join(separator).html_safe
        end
        array + ascii(:space)
      else
        array.join(', ').html_safe
      end
    end

    def format_value(value)
      value
    end

    def format_array_index(value)
      format_array(value){ |v| format_index(v) }
    end

    def format_index(value)
      value = format_value(value)
      @index_link ? primary_key_link(value) : value
    end

    def format_array_export(value)
      value.map{ |v| format_export(v) }.join(array_export_separator)
    end

    def format_export(value)
      value
    end

    def format_input(value)
      value
    end

    def value
      presenter[column_name]
    end

    def nested?
      false
    end

    def method?
      array? || property.nil_or_true?(:virtual?)
    end

    def method_name
      column_name
    end

    def association_names
      []
    end

    def input_label
      klass.human_attribute_name(column_name).upcase_first.html_safe
    end

    def input_control(**attributes)
      input_ type: input_type, **input_attributes, **attributes
    end

    def input_type
      :text
    end

    def input_name
      method_name
    end

    def input_value
      format_input((presenter.new_record? && value.nil?) ? default_value : value)
    end

    def input_css_class
      classes = Set.new(['input'])
      classes << (errors.present? ? 'input-error' : 'input-bordered')
      classes
    end

    def default_input_attributes
      { name: input_name, class: input_css_class, value: input_value, required: required? }
    end

    def default_help
      false
    end

    def search_type
      :string
    end

    def search_operator(operator, value)
      operator
    end

    def errors
      ([property_name] + association_names).uniq.flat_map do |name|
        presenter.errors[name]
      end.uniq
    end

    def primary_key_link(label)
      return unless label
      url = presenter.undiscarded? && presenter.viewable_url
      url ? a_('.link.text-primary', label, href: url) : label
    end

    def sort_link
      return unless sortable?
      url, active, reverse = sort_options
      reverse = !active && reverse || active && !reverse
      title = reverse ? t('admin.misc.desc') : t('admin.misc.asc')
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
      [model.url(q: params[:q].presence, f: params[:f].presence, s: name, r: reverse), active, reverse]
    end

    def sort_column
      return @sort_column if defined? @sort_column
      @sort_column = column_for(sortable)
    end

    def query_column
      @query_column ||= column_for(queryable)
    end

    def query_name
      @query_name ||= begin
        model_param, name, field = query_field
        name = "#{model_param}.#{name}" if field.full_query_name?
        name
      end
    end

    def query_field
      @query_field ||= case (column_name = queryable)
        when true
          [model_param, name, self]
        when false, nil, /[.,]/
          []
        when String, Symbol
          column_name = column_name.to_sym
          [model_param, column_name, property_model.search_section.fields_hash[column_name]]
        else
          raise "invalid :queryable field: [#{column_name}]"
        end
    end

    def model_param
      property_model.to_param
    end

    def property_model
      model
    end

    def property_name
      name
    end

    def column_name
      name
    end

    private

    def column_for(name)
      case name
      when true           then "#{property_model.table_name}.#{column_name}"
      when /[.,]/         then name
      when String, Symbol then "#{property_model.table_name}.#{name}"
      end
    end
  end
end
