class RailsAdmin::Config::Model::Fields::Code < RailsAdmin::Config::Model::Fields::Text
  register_instance_option :readonly?, memoize: true do
    true
  end

  def truncated_value_options
    super.merge!(full: true)
  end
end
