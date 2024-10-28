module Admin
  module Actions
    class Delete < Admin::Action
      def self.weight
        5
      end

      def self.member?
        true
      end

      def self.bulkable?
        true
      end

      def self.http_methods
        [:get, :post]
      end

      def self.icon
        'trash'
      end
    end

    controller_for Delete do
      def delete
        case request.method_symbol
        when :get
          render :delete
        when :post

        end
      end
    end
  end
end
