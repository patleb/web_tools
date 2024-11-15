# frozen_string_literal: true

module Admin
  module Actions
    class Export < Admin::Action
      def self.weight
        1
      end

      def self.collection?
        true
      end

      def self.bulkable?
        !action.trashable?
      end

      def self.searchable?
        true
      end

      def self.http_methods
        [:get, :post]
      end

      def self.icon
        'filetype-csv'
      end

      def presenters?
        request.post?
      end
    end

    controller Export do
      case request.method_symbol
      when :get
        render :export
      when :post

      end
    end
  end
end
