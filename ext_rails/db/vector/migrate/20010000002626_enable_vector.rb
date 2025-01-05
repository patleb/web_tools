class EnableVector < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'vector'
    enable_extension 'aggs_for_vecs'
  end
end
