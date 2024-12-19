class GeoState < LibMainRecord
  include Searchable

  belongs_to :geo_country

  def self.find_by_similarity(country, *tokens)
    where(country_code: country).similar_to(*tokens).first
  end

  def raw_search_words
    names
  end
end
