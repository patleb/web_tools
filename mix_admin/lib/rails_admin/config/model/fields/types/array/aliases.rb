class RailsAdmin::Config::Model::Fields::Array::Decimal < RailsAdmin::Config::Model::Fields::Array
end

class RailsAdmin::Config::Model::Fields::Array::Float < RailsAdmin::Config::Model::Fields::Array::Decimal
end

class RailsAdmin::Config::Model::Fields::Array::Jsonb < RailsAdmin::Config::Model::Fields::Array::Json
end

class RailsAdmin::Config::Model::Fields::Array::Text < RailsAdmin::Config::Model::Fields::Array::String
end

class RailsAdmin::Config::Model::Fields::Array::Citext < RailsAdmin::Config::Model::Fields::Array::Text
end
