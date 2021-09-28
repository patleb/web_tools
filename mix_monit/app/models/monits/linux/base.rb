module Monits
  module Linux
    class Base < Monits::Base
      def self.host
        Process.host
      end

      def self.usage(value, total)
        return 0.0 if total.zero?
        (100.0 * value / total).ceil(2)
      end
    end
  end
end
