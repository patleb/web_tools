class SearchWord < LibMainRecord
  has_many :searches

  # AND condition is implicit by the spaces in the token
  scope :similar_to, ->(*tokens) {
    return none if tokens.empty?
    where((["#{token_column} % ?"] * tokens.size).join(' OR '), *tokens).order(similarity(*tokens))
  }

  def self.similarity(*tokens, as: nil)
    "(#{tokens.map{ |token| "(#{token_column} <-> #{connection.quote(token)})" }.join(' + ')}) #{"AS #{as}" if as}".sql_safe
  end

  def self.token_column
    @token_column ||= quote_column(:token)
  end
end
