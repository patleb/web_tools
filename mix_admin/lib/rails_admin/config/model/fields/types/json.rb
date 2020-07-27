class RailsAdmin::Config::Model::Fields::Json < RailsAdmin::Config::Model::Fields::Base
  require_rel 'json'

  include self::Formatter

  register_instance_option :formatted_value do
    format_json if value
  end

  register_instance_option :truncated?, memoize: true do
    true
  end

  register_instance_option :readonly?, memoize: true do
    true
  end

  def virtual?
    true
  end

  def truncated_value_options
    super.merge!(full: true)
  end

  def parse_value(value)
    value.present? ? (ActiveSupport::JSON.decode(value) rescue nil) : nil
  end

  def parse_input(params)
    params[name] = parse_value(params[name]) if params[name].is_a? String
  end
end
