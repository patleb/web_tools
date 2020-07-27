# Configuration of the edit view for a new object
class RailsAdmin::Config::Model::Sections::Create < RailsAdmin::Config::Model::Sections::Edit
  register_instance_option :inline? do
    false
  end
end
