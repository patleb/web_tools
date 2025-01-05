class AddTriggersToLibSearches < ActiveRecord::Migration[8.0]
  def change
    add_counter_cache :lib_searches, :search_word, foreign_key: { to_table: :lib_search_words, counter_name: :searches_count }
  end
end
