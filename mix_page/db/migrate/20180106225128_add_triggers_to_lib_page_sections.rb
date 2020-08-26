class AddTriggersToLibPageSections < ActiveRecord::Migration[6.0]
  def change
    add_touch :lib_page_sections, :page, foreign_key: { to_table: :lib_pages }
    add_counter_cache :lib_page_sections, :page, foreign_key: { to_table: :lib_pages, counter_name: :page_sections_count }
  end
end
