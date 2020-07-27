class RailsAdmin::Config::Model::Fields::Timestamp < RailsAdmin::Config::Model::Fields::Datetime
  require_rel 'timestamp'

  include self::Formatter
end
