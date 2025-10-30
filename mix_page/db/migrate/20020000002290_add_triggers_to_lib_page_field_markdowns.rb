class AddTriggersToLibPageFieldMarkdowns < ActiveRecord::Migration[8.0]
  def change
    add_touch :lib_page_field_markdowns, :page_field, foreign_key: { to_table: :lib_page_fields }
  end
end
