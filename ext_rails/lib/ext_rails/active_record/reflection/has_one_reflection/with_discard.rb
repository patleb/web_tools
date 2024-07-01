module ActiveRecord::Reflection::HasOneReflection::WithDiscard
  def discardable
    options[:discardable]
  end
  alias_method :discardable?, :discardable
end

ActiveRecord::Reflection::HasOneReflection.include ActiveRecord::Reflection::HasOneReflection::WithDiscard
