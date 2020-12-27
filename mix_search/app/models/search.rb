class Search < LibRecord
  belongs_to :search_word
  belongs_to :searchable, polymorphic: true

  scope :similar_to, ->(*tokens) { joins(:search_word).merge(SearchWord.similar_to(*tokens)) }

  enum searchable_type: MixSearch.config.available_types

  delegate :token, to: :search_word
end
