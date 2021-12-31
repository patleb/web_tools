class EnableCube < ActiveRecord::Migration[6.1]
  def change
    enable_extension 'cube'
  end
end
