module RailsAdmin::Config::Model::Fields::Json::Formatter
  def format_json(value = self.value)
    value.pretty_json
  end
end
