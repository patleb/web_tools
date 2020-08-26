module ActiveRecord::Migration::WithReference
  ### Usage
  #   add_reference :users, :account, foreign_key: { to_table: :accounts }
  #   add_touch     :users, :account, foreign_key: { to_table: :accounts }
  def add_touch(*args)
    reversible do |dir|
      dir.up{ connection.add_touch(*args) }
      dir.down{ connection.remove_touch(*args) }
    end
  end

  ### Usage
  #   remove_touch     :users, :account
  #   remove_reference :users, :account, foreign_key: { to_table: :accounts }
  def remove_touch(*args)
    reversible do |dir|
      dir.up{ connection.remove_touch(*args) }
      dir.down{ connection.add_touch(*args) }
    end
  end

  ### Usage
  #   add_column        :accounts, :users_count, :integer, null: false, default: 0
  #   add_reference     :users, :account, foreign_key: { to_table: :accounts }
  #   add_counter_cache :users, :account, foreign_key: { to_table: :accounts, counter_name: :users_count }
  def add_counter_cache(*args)
    reversible do |dir|
      dir.up{ connection.add_counter_cache(*args) }
      dir.down{ connection.remove_counter_cache(*args) }
    end
  end

  ### Usage
  #   remove_counter_cache :users, :account, foreign_key: { to_table: :accounts, counter_name: :users_count }
  #   remove_reference     :users, :account, foreign_key: { to_table: :accounts }
  #   remove_column        :accounts, :users_count
  def remove_counter_cache(*args)
    reversible do |dir|
      dir.up{ connection.remove_counter_cache(*args) }
      dir.down{ connection.add_counter_cache(*args) }
    end
  end
end
