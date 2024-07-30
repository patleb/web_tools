class EnablePgRepack < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pg_repack'
  end
end
