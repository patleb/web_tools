module Admin
  module Actions
    class Trash < Index
      def self.weight
        4
      end

      def self.bulkable?
        true
      end

      def self.bulk_menu?
        false
      end

      def self.http_methods
        [:get, :post]
      end

      def self.route_fragment?
        true
      end

      def self.icon
        'trash'
      end

      def trash?
        true
      end
    end
  end
end
