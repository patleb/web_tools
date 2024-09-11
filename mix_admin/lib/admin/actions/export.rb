module Admin
  module Actions
    class Export < Admin::Action
      class << self
        def weight
          1
        end

        def collection?
          true
        end

        def bulkable?
          true
        end

        def searchable?
          true
        end

        def http_methods
          [:get, :post]
        end

        def icon
          'filetype-csv'
        end

        def controller
          proc do
            if request.get?
              render :export
            else

            end
          end
        end
      end

      def presenters?
        request.post?
      end
    end
  end
end
