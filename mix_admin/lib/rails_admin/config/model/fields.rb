module RailsAdmin::Config::Model::Fields
  autoload :Base,  'rails_admin/config/model/fields/base'
  autoload :Group, 'rails_admin/config/model/fields/group'
  autoload_dir RailsAdmin::Engine.root.join('lib/rails_admin/config/model/fields/types')

  # TODO factory for virtual attributes
  def self.load(type)
    require 'rails_admin/config/model/fields/types/association/aliases'
    require 'rails_admin/config/model/fields/types/array/aliases'
    require 'rails_admin/config/model/fields/types/aliases'

    if (type = type.to_s).end_with? '_association'
      type_name = "RailsAdmin::Config::Model::Fields::Association::#{type.delete_suffix('_association').camelize}"
    elsif type.end_with? '_array'
      type_name = "RailsAdmin::Config::Model::Fields::Array::#{type.delete_suffix('_array').camelize}"
    else
      type_name = "RailsAdmin::Config::Model::Fields::#{type.camelize}"
    end
    type_name.to_const || raise("Unsupported field datatype '#{type}' #{type_name}")
  end

  # Default field factory loads fields based on their property type or
  # association type.
  #
  # @see RailsAdmin::Config::Model::Fields.factories
  mattr_reader :default_factory
  @@default_factory = proc do |section, property, fields|
    if property.association?
      association = section.abstract_model.associations.find{ |a| a.name.to_s == property.name.to_s }
      type = "#{association.polymorphic? ? :polymorphic : property.type}_association"
      field = RailsAdmin::Config::Model::Fields.load(type).new(section, property.name, association)
    elsif property.array?
      type = "#{property.type}_array"
      field = RailsAdmin::Config::Model::Fields.load(type).new(section, property.name, property)
    else
      field = RailsAdmin::Config::Model::Fields.load(property.type).new(section, property.name, property)
    end
    fields << field
    field
  end

  # Registry of field factories.
  #
  # Field factory is an anonymous function that recieves the parent object,
  # a field property and an array of fields already instantiated.
  #
  # If the factory returns true then that property will not be run through
  # the rest of the registered factories. If it returns false then the
  # arguments will be passed to the next factory.
  #
  # By default a basic factory is registered which loads fields by their
  # database column type. Also a password factory is registered which
  # loads fields if their name is password. Third default factory is a
  # devise specific factory which loads fields for devise user models.
  #
  # @see RailsAdmin::Config::Model::Fields.register_factory
  # @see rails_admin/config/fields/factories/password.rb
  # @see rails_admin/config/fields/factories/devise.rb
  @@factories = [@@default_factory]

  # Build an array of fields by the provided parent object's abstract_model's
  # property and association information. Each property and association is
  # passed to the registered field factories which will populate the fields
  # array that will be returned.
  #
  # @see RailsAdmin::Config::Model::Fields.factories
  def self.factory(section)
    require_rel 'fields/factories'

    raise "#{section.model.model_name} isn't visible" if section.abstract_model.nil?
    # Load fields for all properties
    fields = []
    [section.abstract_model.columns, section.abstract_model.associations].flatten.each do |property|
      # Unless a previous factory has already loaded current field as well
      next if fields.find{ |f| f.name == property.name }
      # Loop through factories until one returns true
      @@factories.find{ |factory| factory.call(section, property, fields) }
    end
    fields
  end

  # Register a field factory to be included in the factory stack.
  #
  # Factories are invoked lifo (last in first out).
  #
  # @see RailsAdmin::Config::Model::Fields.factories
  def self.register_factory(&block)
    @@factories.unshift(block)
  end
end
