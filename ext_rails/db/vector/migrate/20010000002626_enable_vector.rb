class EnableVector < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'vector'
    enable_extension 'aggs_for_vecs'
  end
end
