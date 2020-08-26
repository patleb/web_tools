class EnablePgCounterCache < ActiveRecord::Migration[6.0]
  def up
    create_function_counter_cache
  end

  def down
    drop_function_counter_cache
  end
end
