module Checks
  module Linux
    class Memory < Base
      attribute :size, :integer
      attribute :swap_size, :integer

      def self.list
        [{ id: 'mem', size: host.memory[:ram_used], swap_size: host.memory[:swap_used] }]
      end

      def usage
        self.class.usage(size, self.class.host.ram_total)
      end

      def swap_usage
        self.class.usage(swap_size, self.class.host.swap_total)
      end

      def usage_issue?
        usage >= 95.0
      end

      def usage_warning?
        usage >= 75.0
      end

      def swap_usage_warning?
        swap_usage >= 25.0
      end
    end
  end
end
