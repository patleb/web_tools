class EnablePgDblink < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'dblink'
  end
end
