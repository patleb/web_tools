module ActiveRecord::Migration::WithUnaccent
  def add_unaccent(*args)
    reversible do |dir|
      dir.up{ connection.add_unaccent(*args) }
      dir.down{ connection.remove_unaccent(*args) }
    end
  end

  def remove_unaccent(*args)
    reversible do |dir|
      dir.up{ connection.remove_unaccent(*args) }
      dir.down{ connection.add_unaccent(*args) }
    end
  end
end
