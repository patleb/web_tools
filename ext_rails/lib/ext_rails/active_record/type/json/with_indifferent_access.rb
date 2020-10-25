module ActiveRecord::Type::Json::WithIndifferentAccess
  def deserialize(value)
    decoded_value = super
    decoded_value.is_a?(Hash) ? decoded_value.with_indifferent_access : decoded_value
  end
end

ActiveRecord::Type::Json.prepend ActiveRecord::Type::Json::WithIndifferentAccess
