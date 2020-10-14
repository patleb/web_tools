module ActiveRecord::Reflection::BelongsToReflection::WithList
  def list_parent?
    options[:list_parent]
  end
end

ActiveRecord::Reflection::BelongsToReflection.include ActiveRecord::Reflection::BelongsToReflection::WithList
