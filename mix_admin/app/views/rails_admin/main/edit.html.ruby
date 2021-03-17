modal = request.variant.modal?
path_params = { model_name: @abstract_model.to_param, id: @object.id, modal: (true if modal) }
form_options = {
  url: edit_path(**path_params),
  as: @abstract_model.param_key,
  html: {
    method: "put",
    multipart: true,
    class: "form-horizontal denser",
    data: ({ title: wording_for(:title), pjax: false } if modal),
  }
}

rails_admin_form_for @object, form_options do |form|
  form.generate section: :update
end
