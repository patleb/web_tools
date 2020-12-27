class GeoState < LibRecord
  belongs_to :geo_country
  has_many   :geo_cities
  has_many   :geo_ips
  has_many   :searches, as: :searchable, dependent: :destroy

  def self.find_by_similarity(country, *tokens)
    where(country_code: country).joins(:searches).merge(Search.similar_to(*tokens)).take
  end

  def update_searches
    words_was = searches.eager_load(:search_word).pluck(:id, :token).to_h
    tokens_was = Set.new(words_was.values)
    tokens = Set.new(names.map(&:simplify)) # this is the variable part, otherwise it should be the same logic for other classes
    return if (tokens_changed = tokens ^ tokens_was).empty?

    new_tokens = tokens & tokens_changed
    old_tokens = tokens_was & tokens_changed
    if new_tokens.any?
      SearchWord.insert_all(new_tokens.map{ |token| { token: token } })
      new_words = SearchWord.where(token: new_tokens).pluck(:id)
      new_searches = new_words.map do |word_id|
        { search_word_id: word_id, searchable_id: id, searchable_type: self.class.name }
      end
      Search.insert_all(new_searches)
    end
    if old_tokens.any?
      old_searches = words_was.select{ |_id, token| old_tokens.include? token }.keys
      Search.where(id: old_searches).delete_all
    end
  end
end
