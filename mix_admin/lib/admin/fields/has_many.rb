module Admin
  module Fields
    class HasMany < Association
      register_option :count do
        false
      end

      register_option :limit do
        5
      end

      register_option :eager_load do
        !count && __super__(:eager_load)
      end

      def count_link
        # TODO
      end

      def more_link
        # TODO
      end

      def array?
        true
      end

      def multiple?
        true
      end

      def method_name
        "#{through.to_s.singularize}_ids".to_sym
      end
    end
  end
end
