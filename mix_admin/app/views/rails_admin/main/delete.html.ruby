path_params = { model_name: @abstract_model.to_param, id: @object.id }

h_(
  h4_('.col-sm-12', [
    t("admin.form.are_you_sure_you_want_to_delete_the_object", model_name: @abstract_model.pretty_name.downcase),
    '&ldquo;'.html_safe.no_space!,
    strong_{ @model.with(object: @object).object_label }.no_space!,
    '&rdquo;?'.html_safe,
    span_(t("admin.form.all_of_the_following_related_items_will_be_deleted"))
  ]),
  ul_('.col-sm-12') do
    render partial: "delete_notice", object: @object
  end,
  form_for(@object, url: delete_path(path_params), method: :delete, remote: true) do
    delete_buttons([@object])
  end
)
