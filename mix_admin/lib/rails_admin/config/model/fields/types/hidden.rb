class RailsAdmin::Config::Model::Fields::Hidden < RailsAdmin::Config::Model::Fields::Base
  register_instance_option :view_helper do
    :hidden_field
  end

  register_instance_option :label do
    false
  end

  register_instance_option :help do
    false
  end

  def generic_help
    false
  end
end
