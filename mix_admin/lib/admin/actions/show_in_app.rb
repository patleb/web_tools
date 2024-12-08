# frozen_string_literal: true

module Admin
  module Actions
    class ShowInApp < Admin::Action
      def self.weight
        4
      end

      def self.member?
        true
      end

      def self.icon
        'box-arrow-up-left'
      end

      def section_name
        :show
      end
    end

    controller ShowInApp do
      redirect_to @presenter.to_url
    end
  end
end
