class EnablePgTouch < ActiveRecord::Migration[8.0]
  def up
    create_function_touch
  end

  def down
    drop_function_touch
  end
end
