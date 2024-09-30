# frozen_string_literal: true

module Admin
  module Actions
    class Show < Admin::Action
      def self.member?
        true
      end

      def self.route_fragment?
        false
      end

      def self.icon
        'info-circle'
      end
    end
  end
end
