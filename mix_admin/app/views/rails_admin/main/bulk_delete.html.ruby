path_params = { model_name: @abstract_model.to_param, bulk_ids: @objects.map(&:id) }

h_(
  h5_('.col-sm-12', t('admin.form.bulk_delete')),
  ul_('.col-sm-12') do
    render partial: "delete_notice", collection: @objects
  end,
  form_tag(bulk_delete_path(path_params), method: :delete, remote: true) do
    delete_buttons(@objects)
  end
)
