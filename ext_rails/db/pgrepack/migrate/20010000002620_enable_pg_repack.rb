class EnablePgRepack < ActiveRecord::Migration[6.1]
  def change
    enable_extension 'pg_repack'
  end
end
