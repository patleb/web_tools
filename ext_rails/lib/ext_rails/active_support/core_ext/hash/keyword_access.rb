require "ext_rails/active_support/hash_with_keyword_access"

class Hash
  def with_keyword_access
    ActiveSupport::HashWithKeywordAccess.new(self)
  end
end
