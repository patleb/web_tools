# frozen_string_literal: true

module Admin
  module Actions
    class Edit < Admin::Action
      class << self
        def weight
          2
        end

        def member?
          true
        end

        def inline_menu?
          true
        end

        def http_methods
          [:get, :post]
        end

        def route_fragment?
          true
        end

        def icon
          'pencil-square'
        end

        def controller
          proc do
            case request.method_symbol
            when :get
              render :edit
            when :post

            end
          end
        end
      end
    end
  end
end
