class RailsAdmin::Config::Model::Fields::Password < RailsAdmin::Config::Model::Fields::String
  register_instance_option :view_helper do
    :password_field
  end

  def parse_input(params)
    if params[name].present?
      params[name] = params[name]
    else
      params.delete(name)
    end
  end

  register_instance_option :formatted_value do
    ''.html_safe
  end

  # Password field's value does not need to be read
  def value
    ''
  end

  register_instance_option :visible do
    section.is_a? RailsAdmin::Config::Model::Sections::Edit
  end

  register_instance_option :pretty_value do
    '*****'
  end
end
