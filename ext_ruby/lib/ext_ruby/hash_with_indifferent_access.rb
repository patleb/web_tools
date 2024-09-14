class Hash
  alias_method :to_hwia, :with_indifferent_access
end

ActiveSupport::HashWithIndifferentAccess.class_eval do
  def self.convert_key(key)
    key.is_a?(String) && key.match?(Hash::KEYWORD) ? key.to_sym : key
  end

  private

  def convert_key(key)
    self.class.convert_key(key)
  end
end
