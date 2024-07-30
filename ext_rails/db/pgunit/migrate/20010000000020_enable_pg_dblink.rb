class EnablePgDblink < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'dblink'
  end
end
