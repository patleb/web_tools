class EnableBtreeGist < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'btree_gist'
  end
end
