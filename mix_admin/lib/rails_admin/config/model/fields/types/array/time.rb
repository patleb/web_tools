require_relative '../time'

class RailsAdmin::Config::Model::Fields::Array::Time < RailsAdmin::Config::Model::Fields::Array::Datetime
  include RailsAdmin::Config::Model::Fields::Time::Formatter
end
