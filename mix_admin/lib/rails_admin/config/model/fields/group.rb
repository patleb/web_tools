# A container for groups of fields in edit views
class RailsAdmin::Config::Model::Fields::Group
  include RailsAdmin::Config::Proxyable
  include RailsAdmin::Config::Configurable
  include RailsAdmin::Config::Hideable

  attr_reader :name, :abstract_model
  attr_accessor :section
  attr_reader :model

  def initialize(section, name)
    @section = section
    @model = section.model
    @abstract_model = section.abstract_model
    @name = name.to_s.tr(' ', '_').downcase.to_sym
  end

  # Defines a configuration for a field by proxying section's field method
  # and setting the field's group as self
  #
  # @see RailsAdmin::Config::Model::Fields.field
  def field(name, type = nil, &block)
    field = section.field(name, type, &block)
    # Directly manipulate the variable instead of using the accessor
    # as group probably is not yet registered to the section object.
    field.instance_variable_set(:@group, self)
    field
  end

  # Reader for fields attached to this group
  def fields
    section.fields.select{ |f| f.group == self }
  end

  # Defines configuration for fields by their type
  #
  # @see RailsAdmin::Config::Model::Fields.fields_of_type
  def fields_of_type(type, &block)
    selected = section.fields.select{ |f| type == f.type }
    selected.each{ |f| f.instance_eval(&block) } if block
    selected
  end

  # Reader for fields that are marked as visible
  def visible_fields
    section.with(bindings).visible_fields.select{ |f| f.group == self }
  end

  register_instance_option :visible? do
    model.visible?
  end

  # Should it open by default
  register_instance_option :active? do
    true
  end

  # Configurable group label which by default is group's name humanized.
  register_instance_option :label, memoize: :locale do
    section.fields.find{ |f| f.name == name }&.label || name.to_s.humanize
  end

  # Configurable help text
  register_instance_option :help, memoize: :locale do
    nil
  end
end
