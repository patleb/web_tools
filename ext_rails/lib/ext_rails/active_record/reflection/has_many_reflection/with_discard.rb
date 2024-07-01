module ActiveRecord::Reflection::HasManyReflection::WithDiscard
  def discardable
    options[:discardable]
  end
  alias_method :discardable?, :discardable
end

ActiveRecord::Reflection::HasManyReflection.include ActiveRecord::Reflection::HasManyReflection::WithDiscard
