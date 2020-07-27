class RailsAdmin::Config::Model::Fields::Interval < RailsAdmin::Config::Model::Fields::Base
  require_rel 'interval'

  include self::Formatter

  register_instance_option :pretty_value do
    format_interval
  end

  register_instance_option :export_value do
    formatted_value
  end

  register_instance_option :readonly?, memoize: true do
    true
  end

  def virtual?
    true
  end
end
