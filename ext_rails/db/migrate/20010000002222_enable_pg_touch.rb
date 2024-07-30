class EnablePgTouch < ActiveRecord::Migration[7.1]
  def up
    create_function_touch
  end

  def down
    drop_function_touch
  end
end
