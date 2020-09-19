# Configuration of the show view for a new object
class RailsAdmin::Config::Model::Sections::Base
  include RailsAdmin::Config::Proxyable
  include RailsAdmin::Config::Configurable

  attr_reader :section_name, :parent_section_name
  attr_reader :abstract_model
  attr_reader :model

  delegate :klass, to: :abstract_model

  ### WARNING
  # if parent section has been defined and augmented in a later block,
  # then these changes won't propagate to children sections using the former section
  def initialize(model)
    @model = model
    @abstract_model = model.abstract_model
    @section_name = self.class.name.demodulize.underscore.to_sym
    @parent_section_name = self.class.superclass.name.demodulize.underscore.to_sym unless section_name == :base
  end

  # Provides accessor and autoregistering of model's description.
  def description(description = nil)
    # TODO put timezone here if configured
    @description ||= description
  end

  # Accessor for a group
  #
  # If group with given name does not yet exist it will be created. If a
  # block is passed it will be evaluated in the context of the group
  def group(name, &block)
    group = model.groups.find{ |g| name == g.name }
    group ||= (model.groups << RailsAdmin::Config::Model::Fields::Group.new(self, name)).last
    group.tap{ |g| g.section = self }.instance_eval(&block) if block
    group
  end

  # Reader for groups that are marked as visible
  def visible_groups
    model.groups.map{ |g| g.section = self; g.with(bindings) }.select(&:visible?).select do |g| # rubocop:disable Semicolon
      g.visible_fields.present?
    end
  end

  # Defines a configuration for a field.
  def field(name, type = nil, add_to_section = true, translated: false, editable: false, weight: nil, &block)
    if translated
      field(name, type, add_to_section, &block) if translated == :all
      I18n.available_locales.each{ |locale| field!("#{name}_#{locale}", type, add_to_section, &block) }
    else
      name = name.to_sym
      field = _fields.find{ |f| name == f.name }

      # some fields are hidden by default (belongs_to keys, has_many associations in list views.)
      # unhide them if config specifically defines them
      if field
        field.show unless field.instance_variable_get("@#{field.name}_registered").is_a?(Proc)
      end
      # Specify field as virtual if type is not specifically set and field was not
      # found in default stack
      if field.nil? && type.nil?
        field = (_fields << RailsAdmin::Config::Model::Fields.load(:string).new(self, name, nil)).last

        # Register a custom field type if one is provided and it is different from
        # one found in default stack
      elsif type && type != (field.nil? ? nil : field.type)
        if field
          property = field.property
          field = _fields[_fields.index(field)] = RailsAdmin::Config::Model::Fields.load(type).new(self, name, property)
        else
          property = abstract_model.columns.find{ |c| name == c.name }
          property ||= abstract_model.associations.find{ |a| name == a.name }
          field = (_fields << RailsAdmin::Config::Model::Fields.load(type).new(self, name, property)).last
        end
      end

      # If field has not been yet defined add some default properties
      if add_to_section && !field.defined
        field.defined = true
        field.weight = weight ? weight : _fields.count(&:defined)
      end

      # Force editable behavior
      if editable
        field.readonly false
      end

      # If a block has been given evaluate it and sort fields after that
      field.instance_eval(&block) if block
      field
    end
  end

  def field!(name, type = nil, add_to_section = true, editable: nil, **options, &block)
    field(name, type, add_to_section, editable: true, **options, &block)
  end

  # configure a field without adding it.
  def configure(name, type = nil, **options, &block)
    field(name, type, false, **options, &block)
  end

  def configure!(name, type = nil, **options, &block)
    field!(name, type, false, **options, &block)
  end

  # include fields by name and apply an optionnal block to each (through a call to fields),
  # or include fields by conditions if no field names
  def include_fields(*field_names, **options, &block)
    if field_names.empty?
      _fields.select { |f| f.instance_eval(&block) }.each do |f|
        next if f.defined
        f.defined = true
        f.weight = _fields.count(&:defined)
      end
    else
      fields(*field_names, **options, &block)
    end
  end

  # exclude fields by name or by condition (block)
  def exclude_fields(*field_names, translated: false, &block)
    if translated
      exclude_fields(*field_names, &block) if translated == :all
      field_names = field_names.map{ |name| I18n.available_locales.map{ |locale| "#{name}_#{locale}" } }.flatten
      exclude_fields(*field_names, &block)
    else
      field_names.map!(&:to_sym)
      block ||= proc { |f| field_names.include?(f.name) }
      _fields.each{ |f| f.defined = true } if _fields.select(&:defined).empty?
      _fields.select{ |f| f.instance_eval(&block) }.each{ |f| f.defined = false }
    end
  end

  # API candy
  alias_method :exclude_fields_if, :exclude_fields
  alias_method :include_fields_if, :include_fields

  def include_all_fields
    include_fields_if{ true }
  end

  # Returns all field configurations for the model configuration instance. If no fields
  # have been defined returns all fields. Defined fields are sorted to match their
  # order property. If order was not specified it will match the order in which fields
  # were defined.
  #
  # If a block is passed it will be evaluated in the context of each field
  def fields(*field_names, translated: false, &block)
    if translated
      fields(*field_names, &block) if translated == :all
      field_names = field_names.map{ |name| I18n.available_locales.map{ |locale| "#{name}_#{locale}" } }.flatten
      fields(*field_names, &block)
    else
      return all_fields if field_names.empty? && !block
      field_names.map!(&:to_sym)

      if field_names.empty?
        defined = _fields.select(&:defined)
        defined = _fields if defined.empty?
      else
        defined = field_names.map{ |name| _fields.find{ |f| f.name == name } }
      end
      defined.map do |f|
        raise _undefined_message(defined, field_names) if f.nil?
        unless f.defined
          f.defined = true
          f.weight = _fields.count(&:defined)
        end
        f.instance_eval(&block) if block
        f
      end
    end
  end

  # Defines configuration for fields by their type.
  def fields_of_type(type, &block)
    _fields.select { |f| type == f.type }.map! { |f| f.instance_eval(&block) } if block
  end

  # Accessor for all fields
  def all_fields
    ((ro_fields = _fields(true)).select(&:defined).presence || ro_fields).map do |f|
      f.section = self
      f
    end
  end

  # Get all fields defined as visible, in the correct order.
  def visible_fields
    all_fields.map{ |f| f.with(bindings) }.select(&:visible?).stable_sort_by(&:weight)
  end

  protected

  # Raw fields.
  # Recursively returns model section's raw fields
  # Duping it if accessed for modification.
  def _fields(readonly = false)
    return @_fields if @_fields
    return @_ro_fields if readonly && @_ro_fields

    if section_name == :base
      @_ro_fields = @_fields = RailsAdmin::Config::Model::Fields.factory(self)
    else
      # model is RailsAdmin::Config::Model, recursion is on Section's classes
      @_ro_fields ||= _parent_fields.clone.freeze
    end
    readonly ? @_ro_fields : (@_fields ||= @_ro_fields.map(&:clone))
  end

  private

  def _parent_fields
    model.send(parent_section_name)._fields(true)
  end

  def _undefined_message(defined, field_names)
    undefined_fields = field_names.zip(defined).to_h.select{ |_, k| k.nil? }.keys
    "section '#{section_name}' has undefined fields: #{undefined_fields.map(&:to_sym)}"
  end
end
