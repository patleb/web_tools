module ActiveRecord::Migration::WithReference
  ### Usage
  #   add_reference :users, :account, foreign_key: { to_table: :accounts }
  #   add_touch     :users, :account, foreign_key: { to_table: :accounts }
  def add_touch(...)
    reversible do |dir|
      dir.up{ connection.add_touch(...) }
      dir.down{ connection.remove_touch(...) }
    end
  end

  ### Usage
  #   remove_touch     :users, :account
  #   remove_reference :users, :account, foreign_key: { to_table: :accounts }
  def remove_touch(...)
    reversible do |dir|
      dir.up{ connection.remove_touch(...) }
      dir.down{ connection.add_touch(...) }
    end
  end

  ### Usage
  #   add_column        :accounts, :users_count, :integer, null: false, default: 0
  #   add_reference     :users, :account, foreign_key: { to_table: :accounts }
  #   add_counter_cache :users, :account, foreign_key: { to_table: :accounts, counter_name: :users_count }
  def add_counter_cache(...)
    reversible do |dir|
      dir.up{ connection.add_counter_cache(...) }
      dir.down{ connection.remove_counter_cache(...) }
    end
  end

  ### Usage
  #   remove_counter_cache :users, :account, foreign_key: { to_table: :accounts, counter_name: :users_count }
  #   remove_reference     :users, :account, foreign_key: { to_table: :accounts }
  #   remove_column        :accounts, :users_count
  def remove_counter_cache(...)
    reversible do |dir|
      dir.up{ connection.remove_counter_cache(...) }
      dir.down{ connection.add_counter_cache(...) }
    end
  end
end
