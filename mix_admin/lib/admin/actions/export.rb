# frozen_string_literal: true

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
      end

      def presenters?
        request.post?
      end
    end

    controller_for Export do
      def export
        case request.method_symbol
        when :get
          render :export
        when :post

        end
      end
    end
  end
end
