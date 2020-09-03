class RailsAdmin::Config::Model::Fields::Array::String < RailsAdmin::Config::Model::Fields::Array
  register_instance_option :array_bullet, memoize: true do
    '- '.html_safe
  end

  def array_separator
    '<br>'.html_safe
  end
end
