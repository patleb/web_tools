module Admin
  module Actions
    class Trash < Index
      def self.weight
        4
      end

      def self.route_fragment?
        true
      end

      def self.icon
        'trash'
      end

      def trashable?
        true
      end
    end
  end
end
