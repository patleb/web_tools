class EnableBtreeGin < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'btree_gin'
  end
end
