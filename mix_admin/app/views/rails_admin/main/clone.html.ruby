form_options = {
  url: new_path(model_name: @abstract_model.to_param),
  as: @abstract_model.param_key,
  html: {
    multipart: true,
    class: "form-horizontal denser"
  }
}

# TODO https://github.com/moiristo/deep_cloneable
# TODO https://github.com/danielpclark/PolyBelongsTo
rails_admin_form_for @object.amoeba_dup, form_options do |form|
  form.generate section: :create
end
