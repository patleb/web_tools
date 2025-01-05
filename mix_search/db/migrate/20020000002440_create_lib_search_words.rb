class CreateLibSearchWords < ActiveRecord::Migration[8.0]
  def change
    create_table :lib_search_words do |t|
      t.string :token,          null: false, index: { unique: true }
      t.bigint :searches_count, null: false, default: 0

      t.timestamps
    end

    ### NOTE
    # https://stackoverflow.com/questions/43867449/optimizing-a-postgres-similarity-query-pg-trgm-gin-index
    # https://alexklibisz.com/2022/02/18/optimizing-postgres-trigram-search
    # GiST supports filtering and sorting, whereas GIN only supports filtering
    add_index :lib_search_words, :token, using: :gist, opclass: :gist_trgm_ops,
      name: 'index_lib_search_words_on_token_trgm'
  end
end
