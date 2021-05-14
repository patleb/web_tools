module Checks
  module Linux
    class Disk < Base
      alias_attribute :path, :id
      attribute       :size, :integer
      attribute       :reads, :integer
      attribute       :writes, :integer
      attribute       :inodes_usage, :float

      def self.list
        return [] unless (disk = host.disks[disk_path])
        [{
          id: disk_path, size: disk[:fs_used],
          reads: counter_value(disk[:io_size][0], snapshot[:io_size][0]),
          writes: counter_value(disk[:io_size][1], snapshot[:io_size][1]),
          inodes_usage: host.disks_inodes[disk_path].to_f,
        }]
      end

      def self.snapshot
        m_access(:snapshot){ Host.snapshot&.dig(:disks, disk_path) || { io_size: [0, 0] } }
      end

      def self.disk_path
        '/'
      end

      def usage
        self.class.usage(size, self.class.host.disks[self.class.disk_path][:fs_total])
      end

      def usage_issue?
        usage >= 90.0
      end

      def usage_warning?
        usage >= 80.0
      end
    end
  end
end
