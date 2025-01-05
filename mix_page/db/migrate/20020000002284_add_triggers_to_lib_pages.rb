class AddTriggersToLibPages < ActiveRecord::Migration[8.0]
  def change
    add_touch :lib_pages, :page_layout, foreign_key: { to_table: :lib_pages }
    add_counter_cache :lib_pages, :page_layout, foreign_key: { to_table: :lib_pages, counter_name: :page_templates_count }
  end
end
