module Tensor
  Base.class_eval do
    module self::WithOverrides
      def shape
        super.to_a
      end
    end
    prepend self::WithOverrides
  end
end
