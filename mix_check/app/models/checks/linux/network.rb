module Checks
  module Linux
    class Network < Base
      attribute :bytes_in, :integer
      attribute :bytes_out, :integer

      def self.list
        [{
          id: 'net',
          bytes_in: counter_value(host.network[0], snapshot[0]),
          bytes_out: counter_value(host.network[1], snapshot[1]),
        }]
      end

      def self.snapshot
        m_access(:snapshot){ Host.snapshot&.dig(:network) || [0, 0] }
      end
    end
  end
end
