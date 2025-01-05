class EnablePgDblink < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'dblink'
  end
end
