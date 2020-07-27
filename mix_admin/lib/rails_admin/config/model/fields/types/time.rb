class RailsAdmin::Config::Model::Fields::Time < RailsAdmin::Config::Model::Fields::Datetime
  require_rel 'time'

  include self::Formatter

  def parse_value(value)
    parent_value = super(value)
    return unless parent_value
    value_with_tz = parent_value.in_time_zone
    DateTime.parse(value_with_tz.strftime('%Y-%m-%d %H:%M:%S'))
  end
end
