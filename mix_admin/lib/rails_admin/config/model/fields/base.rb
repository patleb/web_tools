class RailsAdmin::Config::Model::Fields::Base
  include RailsAdmin::Config::Proxyable
  include RailsAdmin::Config::Configurable
  include RailsAdmin::Config::Hideable

  attr_reader :name, :property, :abstract_model
  attr_accessor :defined, :weight, :section, :inline_create
  attr_reader :model

  delegate :klass, to: :abstract_model

  def initialize(section, name, property)
    @section = section
    @model = section.model
    @abstract_model = section.abstract_model
    @defined = false
    @name = name.to_sym
    @weight = 0
    @property = property
  end

  # Register a group instance variable and accessor methods for objects
  # extending the has groups mixin. The extended objects must implement
  # reader for a section object which includes this module.
  #
  # @see RailsAdmin::Config::Model::Sections::Base.group
  # @see RailsAdmin::Config::Model::Fields::Group
  def group(name = nil)
    @group = section.group(name) unless name.nil? # setter
    @group ||= section.group(:default) # getter
  end

  def visible_field?
    returned = true
    (RailsAdmin.config.default_hidden_fields || {}).each do |section_name, fields|
      section_class = ActiveSupport::Dependencies.constantize("RailsAdmin::Config::Model::Sections::#{section_name.to_s.camelize}")
      next unless section.is_a? section_class
      break (returned = false) if fields.include? name
    end
    returned
  end

  # TODO should be the base non-configurable and use everywhere visible_field?
  register_instance_option :visible? do
    property.nil_or_true?(:visible?, object) && visible_field?
  end

  register_instance_option :index_visible? do
    visible?
  end

  register_instance_option :export_visible? do
    property.nil_or_true?(:exportable?) && visible?
  end

  register_instance_option :css_class do
    "#{self.name}_field"
  end

  def css_classes(section = nil)
    case section
    when :table
      "#{css_classes} js_table_column_#{name}"
    when :table_head
      "#{css_classes(:table)} js_table_column_head"
    when :table_update
      "#{css_classes(:table)} js_table_update_wrapper js_table_update_readonly"
    when :table_create
      "#{css_classes(:table)} js_table_create_cell"
    when :form
      "#{css_classes} form-group control-group#{' error' if errors.present?}"
    when :term
      "#{css_classes} label label-info"
    when :definition
      "#{css_classes} well"
    else
      "#{css_class} #{type_css_class}"
    end
  end

  def type_css_class
    "#{type}_type#{' array_type' if array?}#{' association_type' if association?}"
  end

  def array?
    false
  end

  def virtual?
    property.nil? || property.true?(:virtual?)
  end

  register_instance_option :virtual_queryable, memoize: true do
    false
  end

  register_instance_option :sortable, memoize: true do
    property.try(:sortable?) || !virtual? || virtual_queryable || children_fields.first || false
  end

  register_instance_option :searchable, memoize: true do
    property.try(:searchable?) || !virtual? || virtual_queryable || children_fields.first || false
  end

  register_instance_option :queryable?, memoize: true do
    property.try(:searchable?) || !virtual? || virtual_queryable
  end

  register_instance_option :filterable? do
    !virtual_queryable && searchable
  end

  register_instance_option :search_operator, memoize: true do
    RailsAdmin.config.default_search_operator
  end

  # serials and dates are reversed in list, which is more natural (last modified items first).
  register_instance_option :sort_reverse?, memoize: true do
    false
  end

  # list of columns I should search for that field [{ column: 'table_name.column', type: field.type }, {..}]
  register_instance_option :searchable_columns, memoize: true do
    case searchable
    when true
      [{ column: %{"#{abstract_model.table_name}"."#{name}"}, type: type }]
    when false
      []
    when :all # valid only for associations
      table_name = associated_model.abstract_model.table_name
      associated_model.index.visible_fields.map{ |f| {column: "#{table_name}.#{f.name}", type: f.type} }
    else
      [searchable].flatten.map do |f|
        if f.is_a?(String) && f.include?('.')                            #  table_name.column
          table_name, column_name = f.split '.'
          column_type = nil
        elsif f.is_a?(Hash)                                              #  <Model|table_name> => <attribute|column>
          am = f.keys.first.is_a?(Class) && RailsAdmin::AbstractModel.find(f.keys.first)
          table_name = am&.table_name || f.keys.first
          column_name = f.values.first
          column = am&.columns&.find{ |c| c.name == f.values.first.to_sym }
          column_type = column&.type
        else                                                             #  <attribute|column>
          am = (association? ? associated_model.abstract_model : abstract_model)
          table_name = am.table_name
          column_name = f
          column = am.columns.find{ |c| c.name == f.to_sym }
          column_type = column&.type
        end
        { column: %{"#{table_name}"."#{column_name}"}, type: (column_type || :string) }
      end
    end
  end

  register_instance_option :formatted_value do
    value
  end

  # output for pretty printing (show, index, export)
  register_instance_option :pretty_value do
    value = formatted_value
    if simple_formatted? && value.present?
      safe_join(value.to_s.strip.split("\n").map{ |para| ERB::Util.html_escape(para) }, pretty_separator)
    else
      value
    end
  end

  register_instance_option :pretty_blank, memoize: :locale do
    ' - '.html_safe
  end

  register_instance_option :index_value do
    if primary_key? && !trash_action?
      primary_key_link
    elsif truncated?
      truncated_value
    else
      pretty_value
    end
  end

  # output for printing in export view (developers beware: no Current.view and no data!)
  register_instance_option :export_value do
    simple_formatted? ? formatted_value : pretty_value
  end

  register_instance_option :truncated?, memoize: true do
    false
  end

  register_instance_option :simple_formatted?, memoize: true do
    false
  end

  def pretty_value_or_blank
    pretty_value.presence || pretty_blank
  end

  def index_value_or_blank
    index_value.presence || pretty_blank
  end

  def export_value_or_blank
    export_value.presence || pretty_blank
  end

  def pretty_separator
    simple_formatted? ? '<br>'.html_safe : ' '
  end

  def truncated_value_options
    simple_format =
    { length: section.truncate_length, separator: pretty_separator, fallback: ' ', escape: !simple_formatted? }
  end

  def truncated_value(value = pretty_value.to_s, options = truncated_value_options)
    length, separator, fallback, escape = options.values_at(:length, :separator, :fallback, :escape)
    if length && (less, more = value.partition_at(length, separator: separator, fallback: fallback)) && more.present?
      h_(
        span_('.js_table_less_content', less, escape: escape),
        span_('.js_table_expand_cell', ["…", i_('.fa.fa-chevron-right')]),
        span_('.js_table_collapse_cell', [i_('.fa.fa-chevron-down'), ('&nbsp;' * 3).html_safe]),
        if options[:full]
          div_('.js_table_full_content', value, escape: escape)
        else
          div_('.js_table_more_content', more.delete_prefix(separator), escape: escape)
        end,
      )
    else
      value
    end
  end

  # Accessor for field's help text displayed below input field.
  register_instance_option :help do
    readonly? ? false : generic_field_help
  end

  register_instance_option :html_attributes do
    { required: required? }
  end

  register_instance_option :default_value do
    property.try(:default)
  end

  # Accessor for field's label.
  #
  # @see RailsAdmin::AbstractModel.columns
  register_instance_option :label, memoize: :locale do
    property.try(:label)&.humanize || klass.human_attribute_name(name)
  end

  # Accessor for field's maximum length per database.
  #
  # @see RailsAdmin::AbstractModel.columns
  register_instance_option :length, memoize: true do
    property.try(:length)
  end

  # Accessor for field's length restrictions per validations
  #
  register_instance_option :valid_length, memoize: true do
    klass.validators_on(name).find{ |v| v.kind == :length }.try(&:options) || {}
  end

  # Accessor for whether this is field is mandatory.
  #
  # @see RailsAdmin::AbstractModel.columns
  register_instance_option :required? do
    next true if property.nil_or_true?(:required?, object) && property.nil?(:default)
    !!([name] + children_fields).uniq.find do |column_name|
      klass.validators_on(column_name).find do |v|
        next unless !(v.options[:allow_nil] || v.options[:allow_blank])
        next unless [:presence, :numericality, :attachment_presence].include?(v.kind)
        next unless (v.options[:on] == required_context || v.options[:on].blank?)
        (v.options[:if].blank? && v.options[:unless].blank?)
      end
    end
  end

  # Accessor for whether this is a serial field (aka. primary key, identifier).
  #
  # @see RailsAdmin::AbstractModel.columns
  register_instance_option :primary_key?, memoize: true do
    abstract_model.primary_key.to_sym == name
  end

  register_instance_option :view_helper do
    :text_field
  end

  register_instance_option :readonly? do
    !editable?
  end

  # init status in the view
  register_instance_option :active? do
    false
  end

  # columns mapped (belongs_to, paperclip, etc.). First one is used for searching/sorting by default
  register_instance_option :children_fields do
    []
  end

  register_instance_option :render do
    div_(class: 'input-group') do
      form.send view_helper, method_name, html_attributes.reverse_merge(value: form_value, class: 'form-control', required: required)
    end
  end

  def editable?
    !property.nil_or_true?(:readonly?, object)
  end

  def association?
    false
  end

  # Reader for validation errors of the bound object
  def errors
    ([name] + children_fields).uniq.map do |column_name|
      object.errors[column_name]
    end.uniq.flatten
  end

  def required_context
    object ? (object.persisted? ? :update : :create ) : :nil
  end

  # Reader whether field is optional.
  #
  # @see RailsAdmin::Config::Model::Fields::Base.register_instance_option :required?
  def optional?
    !required?
  end

  # Inverse accessor whether this field is required.
  #
  # @see RailsAdmin::Config::Model::Fields::Base.register_instance_option :required?
  def optional(state = nil, &block)
    if !state.nil? || block
      required state.nil? ? proc { false == instance_eval(&block) } : false == state
    else
      optional?
    end
  end

  # Writer to make field optional.
  #
  # @see RailsAdmin::Config::Model::Fields::Base.optional
  def optional=(state)
    optional(state)
  end

  # Reader for field's type
  def type
    @type ||= self.class.name.to_s.demodulize.underscore.to_sym
  end

  # Reader for field's value
  def value
    object.safe_send(name)
  rescue NoMethodError => e
    raise e.exception <<-EOM.gsub(/^\s{10}/, '')
    #{e.message}
    If you want to use a RailsAdmin virtual field(= a field without corresponding instance method),
    you should declare 'formatted_value' in the field definition.
      field :#{name} do
        formatted_value{ object.call_some_method }
      end
    EOM
  end

  # Reader for nested attributes
  register_instance_option :nested_options do
    false
  end

  # Allowed methods for the field in forms
  register_instance_option :allowed_methods do
    [method_name]
  end

  register_instance_option :inline_update?, memoize: true do
    false
  end

  register_instance_option :dynamic_column? do
    !primary_key?
  end

  def generic_help
    (required? ? I18n.t('admin.form.required') : I18n.t('admin.form.optional')) + '. '
  end

  def generic_field_help
    return [generic_help, property.help].join("\n").html_safe if property.try(:help) # TODO I18n
    model = abstract_model.model_name.underscore
    model_lookup = "admin.help.#{model}.#{name}".to_sym
    translated = I18n.t(model_lookup, help: generic_help, default: [generic_help])
    (translated.is_a?(Hash) ? translated.to_a.first[1] : translated).html_safe
  end

  def parse_value(value)
    value
  end

  def parse_input(_params)
    # overriden
  end

  def inverse_of
    nil
  end

  def method_name
    name
  end

  def form_value
    form_default_value.nil? ? formatted_value : form_default_value
  end

  def form_default_value
    (default_value if object.new_record? && value.nil?)
  end

  def primary_key_link
    if (path = authorized_path_for(:show, abstract_model, object))
      a_ '.pjax', pretty_value, href: path
    elsif (path = authorized_path_for(:edit, abstract_model, object))
      a_ '.pjax', pretty_value, href: path
    else
      pretty_value
    end
  end
end
