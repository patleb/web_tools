class RailsAdmin::Config::Model::Fields::Wysiwyg < RailsAdmin::Config::Model::Fields::Text
  register_instance_option :html_attributes do # TODO make it configurable like :datepicker_options
    {
      required: required?,
      class: 'form-control js_field_input',
      data: { element: 'wysiwyg' }
    }
  end
end
