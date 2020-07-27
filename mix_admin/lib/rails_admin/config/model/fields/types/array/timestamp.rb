require_relative '../timestamp'

class RailsAdmin::Config::Model::Fields::Array::Timestamp < RailsAdmin::Config::Model::Fields::Array::Datetime
  include RailsAdmin::Config::Model::Fields::Timestamp::Formatter
end
