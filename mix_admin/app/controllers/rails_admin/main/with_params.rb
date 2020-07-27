module RailsAdmin::Main::WithParams
  private

  def sanitize_params_for!(section, model = @model, target_params = params[@abstract_model.param_key])
    return unless target_params.present?
    fields = model.send(section).with(object: @object).visible_fields
    allowed_methods = fields.map(&:allowed_methods).flatten.uniq.map(&:to_s) << 'id' << '_destroy'
    fields.each { |field| field.parse_input(target_params) }
    target_params.slice!(*allowed_methods)
    target_params.permit!
    fields.select(&:nested_options).each do |association|
      children_params = association.multiple? ? target_params[association.method_name]&.values : [target_params[association.method_name]].compact
      (children_params || []).each do |children_param|
        sanitize_params_for!(:nested, association.associated_model, children_param)
      end
    end
  end
end
