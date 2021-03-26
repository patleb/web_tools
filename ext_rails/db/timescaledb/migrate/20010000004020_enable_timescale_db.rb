class EnableTimescaleDb < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'timescaledb'
  end
end
