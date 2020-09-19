class RailsAdmin::Config::Model::Fields::Text < RailsAdmin::Config::Model::Fields::String
  register_instance_option :truncated?, memoize: true do
    true
  end

  # TODO https://github.com/jaredreich/pell

  # TODO
  # register_instance_option :formatted_value do
  #   if value.present?
  #     simple_format(value)
  #   end
  # end

  register_instance_option :html_attributes do
    {
      maxlength: max_length,
      cols: 52,
      rows: [max_length && (max_length / 52.0).ceil, 3].compact.max,
    }
  end

  register_instance_option :render do
    div_ class: 'input-group' do
      form.text_area method_name,
        html_attributes.reverse_merge(
          value: form_value, class: 'form-control', required: required
        )
    end
  end
end
