class EnablePgDblink < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'dblink'
  end
end
