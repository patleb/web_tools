class CreateLibTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_tasks, id: false do |t|
      t.primary_key :name, :integer
      t.integer     :state,     null: false, default: 0
      t.text        :output
      t.boolean     :notify,    null: false, default: false
      t.interval    :durations, null: false, array: true, default: []

      t.userstamps
      t.timestamps
    end
  end
end
