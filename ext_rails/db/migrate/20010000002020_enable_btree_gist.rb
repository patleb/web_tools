class EnableBtreeGist < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'btree_gist'
  end
end
