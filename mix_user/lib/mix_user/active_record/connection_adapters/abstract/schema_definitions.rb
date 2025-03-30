module ActiveRecord
  module ConnectionAdapters
    module Abstract
      TableDefinition.class_eval do
        def userstamps(**options)
          options = { foreign_key: { to_table: :lib_users, on_delete: :nullify } }.merge(options)
          belongs_to(:creator, **options)
          belongs_to(:updater, **options)
        end

        def creator(**options)
          options = { foreign_key: { to_table: :lib_users, on_delete: :nullify } }.merge(options)
          belongs_to(:creator, **options)
        end

        def updater(**options)
          options = { foreign_key: { to_table: :lib_users, on_delete: :nullify } }.merge(options)
          belongs_to(:updater, **options)
        end
      end

      Table.class_eval do
        def userstamps(**)
          @base.add_userstamps(name, **)
        end

        def creator(**)
          @base.add_creator(name, **)
        end

        def updater(**)
          @base.add_updater(name, **)
        end
      end
    end
  end
end
