class EnableLtree < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'ltree'
  end
end
