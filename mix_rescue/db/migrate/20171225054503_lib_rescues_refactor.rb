class LibRescuesRefactor < ActiveRecord::Migration[6.0]
  def change
    remove_column :lib_rescues, :message
    add_column    :lib_rescues, :message, :citext, null: false
    remove_column :lib_rescues, :data if column_exists? :lib_rescues, :data
    remove_index  :lib_rescues, column: :message if index_name_exists? :lib_rescues, index_name(:lib_rescues, column: :message)
  end
end
