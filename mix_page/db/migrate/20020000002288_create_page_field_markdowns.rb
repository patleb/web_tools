class CreatePageFieldMarkdowns < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_page_field_markdowns do |t|
      t.jsonb      :json_data,  null: false, default: {}
      t.belongs_to :page_field, null: false, foreign_key: { to_table: :lib_page_fields }

      t.timestamps
    end
  end
end
