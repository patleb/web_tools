class CreateMixRescues < ActiveRecord::Migration[5.1]
  def up
    drop_table :mr_rescues if table_exists? :mr_rescues

    unless table_exists? :mix_rescues
      create_table :mix_rescues do |t|
        t.string   :type,       null: false
        t.string   :exception,  null: false
        t.text     :message,    null: false
        t.jsonb    :data,       null: false, default: {}

        t.timestamps
      end

      add_index :mix_rescues, [:type, :exception]
      add_index :mix_rescues, :created_at
      add_index :mix_rescues, [:message, :data], using: :gin
    end
  end

  def down
    drop_table :mr_rescues if table_exists? :mr_rescues
    drop_table :mix_rescues if table_exists? :mix_rescues
  end
end
