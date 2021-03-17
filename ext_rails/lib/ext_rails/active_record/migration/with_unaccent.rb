module ActiveRecord::Migration::WithUnaccent
  def add_unaccent(...)
    reversible do |dir|
      dir.up{ connection.add_unaccent(...) }
      dir.down{ connection.remove_unaccent(...) }
    end
  end

  def remove_unaccent(...)
    reversible do |dir|
      dir.up{ connection.remove_unaccent(...) }
      dir.down{ connection.add_unaccent(...) }
    end
  end
end
