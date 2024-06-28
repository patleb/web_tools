module ActiveRecord::Type::Json::WithKeywordAccess
  def deserialize(value)
    memoize(__method__, value) do
      decoded_value = super
      decoded_value.is_a?(Hash) ? decoded_value.with_keyword_access : decoded_value
    end
  end
end

ActiveRecord::Type::Json.prepend ActiveRecord::Type::Json::WithKeywordAccess
