# frozen_string_literal: true

module Admin
  module Actions
    class Show < Admin::Action
      class << self
        def member?
          true
        end

        def route_fragment?
          false
        end

        def icon
          'info-circle'
        end

        def controller
          proc do
            render :show
          end
        end
      end
    end
  end
end
