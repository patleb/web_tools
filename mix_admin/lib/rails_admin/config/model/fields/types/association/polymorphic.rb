class RailsAdmin::Config::Model::Fields::Association::Polymorphic < RailsAdmin::Config::Model::Fields::Association::BelongsTo
  register_instance_option :render do
    # render_filtering
    type_collection = polymorphic_type_collection
    type_column = property.foreign_type.to_s
    selected_type = object.send(type_column)
    collection = associated_collection(selected_type)
    selected_id = object.send(property.name).try(:id)
    column_type_dom_id = form.dom_id(self).sub(method_name.to_s, type_column)
    div_ '.form-inline' do
      div_('.form-group', [
        form.select(type_column, type_collection, { include_blank: true, selected: selected_type },
          class: "form-control",
          id: column_type_dom_id,
          data: { types: polymorphic_types }
        ),
        polymorphic_types.map do |model_name, _model_param|
          current_id = (selected_type == model_name) ? selected_id : nil
          form.select(method_name, collection, { include_blank: true, selected: current_id },
            class: "form-control",
            data: { type: model_name }
          )
        end,
      ])
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

  register_instance_option :allowed_methods do
    [children_fields]
  end

  register_instance_option :eager_load? do
    false
  end

  def associated_collection(type)
    return [] if type.blank?
    model = RailsAdmin.model(type)
    model.abstract_model.all.map do |object|
      [model.with(object: object).object_label, object.id]
    end
  end

  def associated_model
    @associated_model ||= property.klass.map{ |type| RailsAdmin.model(type) }.select(&:visible?)
  end

  def polymorphic_type_collection
    associated_model.map do |model|
      [model.label, model.klass.name]
    end
  end

  def polymorphic_types
    associated_model.each_with_object({}) do |model, types|
      types[model.klass.name] = model.abstract_model.to_param
    end
  end

  # Reader for field's value
  def value
    object.send(property.name)
  end
end
