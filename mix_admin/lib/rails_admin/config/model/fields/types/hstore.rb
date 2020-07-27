class RailsAdmin::Config::Model::Fields::Hstore < RailsAdmin::Config::Model::Fields::Base
  register_instance_option :formatted_value do
    value.to_yaml
  end

  def parse_input(params)
    params[name] = if params[name].blank?
      nil
    else
      YAML.safe_load(params[name])
    end
  end
end
