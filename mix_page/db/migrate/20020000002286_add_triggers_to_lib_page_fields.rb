class AddTriggersToLibPageFields < ActiveRecord::Migration[7.1]
  def change
    add_touch :lib_page_fields, :page, foreign_key: { to_table: :lib_pages }
    add_counter_cache :lib_page_fields, :page, foreign_key: { to_table: :lib_pages, counter_name: :page_fields_count }
  end
end
