class ActiveSupport::HashWithKeywordAccess < ActiveSupport::HashWithIndifferentAccess
  def with_keyword_access
    dup
  end

  private

  def convert_key(key)
    key.is_a?(String) && key.match?(Hash::KEYWORD) ? key.to_sym : key
  end
end

class Hash
  def with_keyword_access
    ActiveSupport::HashWithKeywordAccess.new(self)
  end
end

HashWithKeywordAccess = ActiveSupport::HashWithKeywordAccess
