class EnableCube < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'cube'
    enable_extension 'earthdistance'
  end
end
