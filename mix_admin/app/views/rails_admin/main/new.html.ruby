modal = request.variant.modal?
form_options = {
  url: new_path(model_name: @abstract_model.to_param, modal: (true if modal)),
  as: @abstract_model.param_key,
  html: {
    multipart: true,
    class: "form-horizontal denser",
    data: ({ title: wording_for(:title), pjax: false } if modal),
  }
}

rails_admin_form_for @object, form_options do |form|
  form.generate section: :create
end
