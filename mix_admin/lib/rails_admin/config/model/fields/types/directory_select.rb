class RailsAdmin::Config::Model::Fields::DirectorySelect < RailsAdmin::Config::Model::Fields::String
  def data_input(selector)
    html_attributes.merge(data: { input: selector })
  end

  register_instance_option :html_attributes do
    {
      class: 'form-control js_directory_select_input js_pjax_virtual_file',
      type: 'file',
      webkitdirectory: '',
      directory: '',
      title: '&nbsp;'.html_safe,
      required: required?,
    }
  end
end
