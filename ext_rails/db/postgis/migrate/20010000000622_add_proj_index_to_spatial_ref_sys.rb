class AddProjIndexToSpatialRefSys < ActiveRecord::Migration[6.0]
  def change
    add_index :spatial_ref_sys, [:srtext, :proj4text], unique: true
  end
end
