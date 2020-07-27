class RailsAdmin::Config::Model::Fields::Text < RailsAdmin::Config::Model::Fields::Base
  register_instance_option :truncated?, memoize: true do
    true
  end

  # TODO https://github.com/jaredreich/pell

  # TODO
  # register_instance_option :formatted_value do
  #   if value.present?
  #     simple_format(value, {}, sanitize: true)
  #   end
  # end

  register_instance_option :html_attributes do
    {
      required: required?,
      cols: '50',
      rows: '3',
    }
  end

  register_instance_option :render do
    div_ class: 'input-group' do
      form.text_area method_name,
        html_attributes.reverse_merge(
          value: form_value, class: 'form-control', required: required, data: { richtext: false, options: {} }
        )
    end
  end
end
