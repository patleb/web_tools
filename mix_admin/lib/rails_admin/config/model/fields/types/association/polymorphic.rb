class RailsAdmin::Config::Model::Fields::Association::Polymorphic < RailsAdmin::Config::Model::Fields::Association::BelongsTo
  register_instance_option :render do
    selected = value&.to_global_id
    collection = grouped_options_for_select(associated_collection, selected)
    div_ class: bs_form_row do
      form.select(method_name, collection, { include_blank: include_blank?, selected: selected },
        html_attributes.reverse_merge(class: 'form-control')
      )
    end
  end

  # Accessor whether association is visible or not. By default
  # association checks that any of the child models are included in
  # configuration.
  register_instance_option :visible? do
    unless section.is_a? RailsAdmin::Config::Model::Sections::Nested
      associated_model.any?
    end
  end

  register_instance_option :formatted_value do
    (o = value) && RailsAdmin.model(o).with(object: o).object_label
  end

  register_instance_option :sortable do
    false
  end

  register_instance_option :searchable do
    false
  end

  register_instance_option :types, memoize: true do
    property.klass
  end

  def associated_model
    @associated_model ||= types.map{ |type| RailsAdmin.model(type) }.select(&:visible?)
  end

  def associated_collection
    associated_model.map do |model|
      [model.label, model.abstract_model.all.map{ |o| [model.with(object: o).object_label, o.to_global_id] }]
    end
  end

  def method_name
    "#{name}_global_id".to_sym
  end
end
