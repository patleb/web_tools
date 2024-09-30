module Admin
  module Actions
    class Index < Admin::Action
      def self.collection?
        true
      end

      def self.searchable_tab?
        action_name.to_sym != key
      end

      def self.searchable?
        true
      end

      def self.route_fragment?
        false
      end

      def self.icon
        'table'
      end
    end
  end
end
