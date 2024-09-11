module Admin
  module Actions
    class Delete < Admin::Action
      class << self
        def weight
          5
        end

        def member?
          true
        end

        def bulkable?
          true
        end

        def http_methods
          [:get, :post]
        end

        def icon
          'trash'
        end
      end
    end
  end
end
