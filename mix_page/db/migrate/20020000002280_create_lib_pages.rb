class CreateLibPages < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_pages do |t|
      # TODO move uuid V5
      t.uuid       :uuid,                 null: false, default: 'gen_random_uuid()', index: { using: :hash }
      t.integer    :type,                 null: false
      t.integer    :view,                 null: false, index: true
      t.belongs_to :page_layout,          foreign_key: { to_table: :lib_pages }
      t.integer    :page_templates_count, null: false, default: 0
      t.integer    :page_fields_count,    null: false, default: 0
      t.jsonb      :json_data,            null: false, default: {}, index: { using: :gin }
      t.integer    :lock_version,         null: false, default: 0
      t.userstamps
      t.timestamps
      t.datetime   :deleted_at
      t.datetime   :published_at
    end

    add_index :lib_pages, [:type, :deleted_at]
  end
end
