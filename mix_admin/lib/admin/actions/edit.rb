# frozen_string_literal: true

module Admin
  module Actions
    class Edit < Admin::Action
      def self.weight
        2
      end

      def self.member?
        true
      end

      def self.http_methods
        [:get, :post]
      end

      def self.route_fragment?
        true
      end

      def self.icon
        'pencil-square'
      end
    end

    controller_for Edit do
      def edit
        case request.method_symbol
        when :get
          render :edit
        when :post
          @presenter.update! @attributes if @attributes.present?
          on_update_success
        end
      end
    end
  end
end
