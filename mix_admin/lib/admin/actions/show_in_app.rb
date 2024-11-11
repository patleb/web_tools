# frozen_string_literal: true

module Admin
  module Actions
    class ShowInApp < Admin::Action
      def self.member?
        true
      end

      def self.icon
        'eye'
      end
    end

    controller_for ShowInApp do
      def show_in_app
        redirect_to @presenter.to_url
      end
    end
  end
end
