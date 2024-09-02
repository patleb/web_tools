module Monit
  module Linux
    class Base < Monit::Base
      def self.clear
        Monit::Linux::Base.descendants.each(&:m_clear)
        reset
      end

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
