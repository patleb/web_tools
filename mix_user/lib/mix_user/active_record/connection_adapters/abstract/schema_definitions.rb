module ActiveRecord
  module ConnectionAdapters
    module Abstract
      TableDefinition.class_eval do
        def userstamps(**options)
          options = { foreign_key: { to_table: :lib_users, on_delete: :nullify } }.merge(options)
          belongs_to(:creator, **options)
          belongs_to(:updater, **options)
        end
      end

      Table.class_eval do
        def userstamps(**options)
          @base.add_userstamps(name, **options)
        end
      end
    end
  end
end
