module ActiveRecord::Type::Json::WithKeywordAccess
  def deserialize(value)
    decoded_value = super
    decoded_value.is_a?(Hash) ? decoded_value.to_hwka : decoded_value
  end
end

ActiveRecord::Type::Json.prepend ActiveRecord::Type::Json::WithKeywordAccess
