class CreateMrRescues < ActiveRecord::Migration[5.1]
  def change
    create_table :mr_rescues do |t|
      t.string   :type,       null: false
      t.string   :exception,  null: false
      t.text     :message,    null: false
      t.jsonb    :data,       null: false, default: {}

      t.timestamps
    end

    add_index :mr_rescues, [:type, :exception]
    add_index :mr_rescues, :created_at
    add_index :mr_rescues, [:message, :data], using: :gin
  end
end
