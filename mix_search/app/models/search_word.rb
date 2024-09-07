class SearchWord < LibMainRecord
  has_many :searches

  # AND condition is implicit by the spaces in the token
  scope :similar_to, ->(*tokens, locale: :en) {
    tokens = tokens.compact.map(&:simplify.with(locale)).reject{ |token| token.size < 3 }.uniq
    return none if tokens.empty?

    token_column = quote_column(:token)
    where((["#{token_column} % ?"] * tokens.size).join(' OR '), *tokens)
      .order("(#{tokens.map{ |token| "(#{token_column} <-> #{connection.quote(token)})" }.join(' + ')})".sql_safe)
  }
end
