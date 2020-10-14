class RailsAdmin::Config::Model::Fields::Association::Polymorphic < RailsAdmin::Config::Model::Fields::Association::BelongsTo
  register_instance_option :render do
    render_polymorphic # TODO nested + filtering
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
      [
        model.label,
        model.abstract_model.all.map{ |o| [model.with(object: o).object_label, o.to_global_id] }.sort_by(&:first)
      ]
    end.sort_by(&:first)
  end

  def selected_id
    object.send(foreign_type).to_const&.new(id: object.send(foreign_key))&.to_global_id
  end

  def method_name
    "#{name}_global_id".to_sym
  end

  def render_polymorphic
    selected = value&.to_global_id
    collection =
      if associated_model.size > 1
        grouped_options_for_select(associated_collection, selected)
      else
        associated_collection.first.last
      end
    div_('.input-group') do
      form.select(method_name, collection, { include_blank: include_blank?, selected: selected },
        html_attributes.reverse_merge(class: 'form-control')
      )
    end
  end
end
