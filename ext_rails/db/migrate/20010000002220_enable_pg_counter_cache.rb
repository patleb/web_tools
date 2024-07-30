class EnablePgCounterCache < ActiveRecord::Migration[7.1]
  def up
    create_function_counter_cache
  end

  def down
    drop_function_counter_cache
  end
end
