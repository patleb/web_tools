class EnablePgRepack < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pg_repack'
  end
end
