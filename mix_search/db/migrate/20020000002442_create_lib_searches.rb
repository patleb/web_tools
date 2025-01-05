class CreateLibSearches < ActiveRecord::Migration[8.0]
  def change
    create_table :lib_searches do |t|
      t.belongs_to :search_word,     null: false, index: false, foreign_key: { to_table: :lib_search_words }
      t.integer    :occurrences,     null: false, default: 1
      t.integer    :positions,       null: false, default: [0], array: true
      t.bigint     :searchable_id,   null: false
      t.integer    :searchable_type, null: false

      t.timestamps
    end

    add_index :lib_searches, [:search_word_id, :occurrences],
      name: 'index_lib_searches_on_search_word_id'
    add_index :lib_searches, [:searchable_type, :searchable_id, :search_word_id],
      name: 'index_lib_searches_on_searchable', unique: true
  end
end
