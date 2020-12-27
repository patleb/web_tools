class CreateLibSearchWords < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_search_words do |t|
      t.string :token,          null: false, index: { unique: true }
      t.bigint :searches_count, null: false, default: 0

      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end

    # https://stackoverflow.com/questions/43867449/optimizing-a-postgres-similarity-query-pg-trgm-gin-index
    add_index :lib_search_words, :token, using: :gist, opclass: { title: :gist_trgm_ops },
      name: 'index_lib_search_words_on_token_trgm'
  end
end
