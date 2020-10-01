class RailsAdmin::Config::Model::Fields::Citext < RailsAdmin::Config::Model::Fields::String
end

# TODO allow fractional values in filters (frontend)
class RailsAdmin::Config::Model::Fields::Decimal < RailsAdmin::Config::Model::Fields::Base
end

class RailsAdmin::Config::Model::Fields::Float < RailsAdmin::Config::Model::Fields::Decimal
end

class RailsAdmin::Config::Model::Fields::Inet < RailsAdmin::Config::Model::Fields::Base
end

class RailsAdmin::Config::Model::Fields::Int8range < RailsAdmin::Config::Model::Fields::Array::Integer
end

class RailsAdmin::Config::Model::Fields::Jsonb < RailsAdmin::Config::Model::Fields::Json
end

class RailsAdmin::Config::Model::Fields::Ltree < RailsAdmin::Config::Model::Fields::Base
end

class RailsAdmin::Config::Model::Fields::Numrange < RailsAdmin::Config::Model::Fields::Array::Decimal
end

class RailsAdmin::Config::Model::Fields::Tsrange < RailsAdmin::Config::Model::Fields::Array::Timestamp
end

class RailsAdmin::Config::Model::Fields::Uuid < RailsAdmin::Config::Model::Fields::String
end

