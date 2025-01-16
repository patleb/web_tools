class EnableAggsForVecs < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'aggs_for_vecs'
  end
end
