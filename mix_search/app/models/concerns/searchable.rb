module Searchable
  extend ActiveSupport::Concern

  included do
    has_many :searches, as: :searchable, dependent: :destroy
  end

  class_methods do
    def update_searches
      all.each(&:update_searches)
    end

    def similar_to(*tokens)
      tokens = simplify(*tokens)
      similarity = limit(MixSearch.config.tokens_limit)
        .joins(:searches)
        .merge(Search.similar_to(*tokens))
        .pluck(column(primary_key), SearchWord.similarity(*tokens))
        .group_by(&:first)
        .transform_values(&:sum.with(&:last))
      find(similarity.keys).stable_sort_by do |record|
        similarity[record.public_send(primary_key)]
      end
    end

    def simplify(*tokens)
      tokens.compact.map(&:simplify).reject{ |token| token.size < 3 }.uniq
    end
  end

  def raw_search_words
    raise NotImplementedError
  end

  def update_searches
    words_was = searches.eager_load(:search_word).pluck(:id, :token).to_h
    tokens_was = Set.new(words_was.values)
    tokens = Set.new(self.class.simplify(*raw_search_words))
    return if (tokens_changed = tokens ^ tokens_was).empty?

    new_tokens = tokens & tokens_changed
    old_tokens = tokens_was & tokens_changed
    if new_tokens.any?
      SearchWord.insert_all(new_tokens.map{ |token| { token: token } })
      new_words = SearchWord.where(token: new_tokens).ids
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
