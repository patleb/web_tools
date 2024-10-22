class Hash
  alias_method :to_hwia, :with_indifferent_access
end

# NOTE
# (hash_with_indifferent_access[key] ||= {})
# if not assigned already, it returns {} instead of the converted one
# so, either use (hash_with_indifferent_access[key] ||= {}.with_indifferent_access)
# or use (hash[key] ||= {}) and convert the root node after assignments
ActiveSupport::HashWithIndifferentAccess.class_eval do
  def self.convert_key(key)
    key.is_a?(String) && key.match?(Hash::KEYWORD) ? key.to_sym : key
  end

  private

  def convert_key(key)
    self.class.convert_key(key)
  end
end
