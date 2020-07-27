require_relative '../date'

class RailsAdmin::Config::Model::Fields::Array::Date < RailsAdmin::Config::Model::Fields::Array::Datetime
  include RailsAdmin::Config::Model::Fields::Date::Formatter
end
