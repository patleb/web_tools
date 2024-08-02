module ActiveSupport
  SafeBuffer.class_eval do
    module self::WithString
      def initialize(str = '')
        super(str.to_s)
      end
    end
    prepend self::WithString
  end
end
