module Admin
  module Actions
    class Trash < Index
      class << self
        def weight
          4
        end

        def bulkable?
          true
        end

        def bulk_menu?
          false
        end

        def http_methods
          [:get, :post]
        end

        def route_fragment?
          true
        end

        def icon
          'trash'
        end
      end

      def trash?
        true
      end
    end
  end
end
