# TODO https://scoutapm.com/docs/features
module Checks
  module Linux
    class Host < Base
      alias_attribute :ip, :id
      attribute       :cpu_count, :integer
      attribute       :disk_total, :integer
      attribute       :storage_total, :integer
      attribute       :memory_total, :integer
      attribute       :swap_total, :integer

      nests_one  :cpu,      default: proc { Cpu.current }
      nests_one  :disk,     default: proc { Disk.current }
      nests_one  :storage,  default: proc { Storage.current }
      nests_one  :memory,   default: proc { Memory.current }
      nests_one  :network,  default: proc { Network.current }
      nests_one  :postgres, default: proc { Postgres.current }
      nests_one  :ruby,     default: proc { Ruby.current }
      nests_many :sockets,  default: proc { Socket.all }

      validates :cpu, check: true
      validates :disk, check: true
      validates :storage, check: true
      validates :memory, check: true
      validates :ruby, check: true

      def self.list
        [{
          id: host.private_ip,
          cpu_count: host.cpu_count,
          disk_total: host.disks[Disk.disk_path][:fs_total],
          storage_total: host.disks.dig(Storage.disk_path, :fs_total) || 0,
          memory_total: host.ram_total,
          swap_total: host.swap_total,
        }]
      end

      def self.snapshot_key
        [name, host.private_ip, :snapshot]
      end

      def self.snapshot
        m_access(:snapshot){ Global.read(snapshot_key) }
      end

      def self.capture
        last_updated_at = LogLines::Host.last_messages(text_tiny: "#{host.private_ip}%").pick(:updated_at)
        if last_updated_at.nil? || last_updated_at < (Setting[:check_host_interval] - 30.seconds).ago
          Global.write(snapshot_key, host.build_snapshot, expires: false)
          Log.host(current)
          reset
        end
      end
    end
  end
end
