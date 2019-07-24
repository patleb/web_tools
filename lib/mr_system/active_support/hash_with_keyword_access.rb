require 'active_support/hash_with_indifferent_access'

class ActiveSupport::HashWithKeywordAccess < ActiveSupport::HashWithIndifferentAccess
  private

  def convert_key(key)
    key.kind_of?(String) && key.match?(/^_*[a-z]/) ? key.to_sym : key
  end
end
