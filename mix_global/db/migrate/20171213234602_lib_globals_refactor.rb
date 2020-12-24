class LibGlobalsRefactor < ActiveRecord::Migration[6.0]
  def change
    remove_column :lib_globals, :text
    add_column    :lib_globals, :string, :string
  end
end
