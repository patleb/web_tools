module ActiveRecord
  module ConnectionAdapters
    module Abstract
      TableDefinition.class_eval do
        def userstamps(**options)
          belongs_to(:creator, options)
          belongs_to(:updater, options)
        end
      end

      Table.class_eval do
        def userstamps(options = {})
          @base.add_userstamps(name, options)
        end
      end
    end
  end
end
