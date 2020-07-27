class RailsAdmin::Config::Model::Fields::Array::String < RailsAdmin::Config::Model::Fields::Array
  register_instance_option :array_bullet, memoize: true do
    '- '.html_safe
  end

  def array_separator
    '<br>'.html_safe
  end

  def pretty_array
    super.map{ |item| ERB::Util.html_escape(item) }
  end

  def truncated_array_options
    { escape: false }
  end
end
