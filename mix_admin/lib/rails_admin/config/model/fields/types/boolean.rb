class RailsAdmin::Config::Model::Fields::Boolean < RailsAdmin::Config::Model::Fields::Base
  require_rel 'boolean'

  include self::Formatter

  register_instance_option :view_helper do
    :check_box
  end

  # TODO boolean field nil don't show icon on mobile
  register_instance_option :pretty_value do
    pretty_format_boolean
  end

  register_instance_option :export_value do
    export_format_boolean
  end

  register_instance_option :render do
    div_ '.checkbox' do
      label_ '.form_label_boolean' do
        form.send view_helper, method_name, html_attributes.reverse_merge(value: form_value, checked: form_value.to_b, required: required)
      end
    end
  end

  # Accessor for field's help text displayed below input field.
  def generic_help
    ''
  end
end
