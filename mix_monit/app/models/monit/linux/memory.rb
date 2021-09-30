module Monit
  module Linux
    class Memory < Base
      attribute :ram_used, :integer
      attribute :swap_used, :integer

      def self.list
        [{ id: 'mem', ram_used: host.memory[:ram_used], swap_used: host.memory[:swap_used] }]
      end

      def ram_total
        self.class.host.ram_total
      end

      def ram_usage
        self.class.usage(ram_used, ram_total)
      end

      def swap_total
        self.class.host.swap_total
      end

      def swap_usage
        self.class.usage(swap_used, swap_total)
      end

      def ram_usage_issue?
        ram_usage >= Setting[:monit_ram_usage]
      end

      def ram_usage_warning?
        ram_usage >= 75.0
      end

      def swap_usage_warning?
        swap_usage >= 25.0
      end
    end
  end
end
