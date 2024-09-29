module Admin
  module Actions
    class Index < Admin::Action
      class << self
        def collection?
          true
        end

        def searchable_tab?
          action_name.to_sym != key
        end

        def searchable?
          true
        end

        def route_fragment?
          false
        end

        def icon
          'table'
        end
      end
    end
  end
end
