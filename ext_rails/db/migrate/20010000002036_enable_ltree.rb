class EnableLtree < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'ltree'
  end
end
