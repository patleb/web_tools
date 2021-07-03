# TODO https://scoutapm.com/docs/features
module Checks
  module Linux
    class Host < Base
      alias_attribute :ip, :id

      nests_one  :cpu,      default: proc { Cpu.current }
      nests_one  :disk,     default: proc { Disk.current }
      nests_one  :storage,  default: proc { Storage.current }
      nests_one  :memory,   default: proc { Memory.current }
      nests_one  :network,  default: proc { Network.current }
      nests_one  :postgres, default: proc { Postgres.current }
      nests_one  :ruby,     default: proc { Ruby.current }
      nests_many :sockets,  default: proc { Socket.all }

      delegate_to :cpu, :count, prefix: true
      delegate_to :disk, :total, prefix: true
      delegate_to :storage, :total, prefix: true
      delegate_to :memory, :ram_total, :swap_total

      validates :cpu, check: true
      validates :disk, check: true
      validates :storage, check: true
      validates :memory, check: true
      validates :ruby, check: true

      def self.list
        [{ id: host.private_ip }]
      end

      def self.snapshot_key
        [name, host.private_ip, :snapshot]
      end

      def self.snapshot
        m_access(:snapshot){ Global.read(snapshot_key) }
      end

      def self.capture
        last_updated_at = LogLines::Host.last_messages(text_tiny: host.private_ip).pick(:updated_at)
        if last_updated_at.nil? || last_updated_at < (Setting[:check_host_interval] - 30.seconds).ago
          Global.write! snapshot_key, host.build_snapshot
          Log.host(current)
          reset
        end
      end
    end
  end
end
