module Searchable
  extend ActiveSupport::Concern

  included do
    has_many :searches, as: :searchable, dependent: :destroy
  end

  class_methods do
    def similar_to(*tokens)
      joins(:searches).merge(Search.similar_to(*tokens))
    end
  end

  def raw_search_words
    raise NotImplementedError
  end

  def update_searches
    words_was = searches.eager_load(:search_word).pluck(:id, :token).to_h
    tokens_was = Set.new(words_was.values)
    tokens = Set.new(raw_search_words.map(&:simplify))
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
