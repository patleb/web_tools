ActiveSupport::HashWithIndifferentAccess.class_eval do
  private

  def convert_key(key)
    key.is_a?(String) && key.match?(Hash::KEYWORD) ? key.to_sym : key
  end
end
