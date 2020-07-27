# Configuration of the navigation view
class RailsAdmin::Config::Model::Sections::Export < RailsAdmin::Config::Model::Sections::Base
  register_instance_option :choose? do
    false
  end

  register_instance_option :choose_prefix do
    nil
  end

  register_instance_option :extra_formats do
    [:json, :xml]
  end
end
