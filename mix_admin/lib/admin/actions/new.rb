# frozen_string_literal: true

module Admin
  module Actions
    class New < Admin::Action
      class << self
        def weight
          3
        end

        def collection?
          true
        end

        def http_methods
          [:get, :post]
        end

        def icon
          'plus-circle'
        end
      end
    end

    controller_for New do
      def new
        case request.method_symbol
        when :get
          render :new
        when :post

        end
      end
    end
  end
end
