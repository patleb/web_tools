module Checks
  module Linux
    class Worker < Base
      alias_attribute :pid, :id
      attribute       :ppid, :integer
      attribute       :name
      attribute       :command
      attribute       :state
      attribute       :nice, :integer
      attribute       :threads, :integer
      attribute       :start_time, :datetime
      attribute       :memory_size, :integer
      attribute       :inodes_count, :integer

      def self.list
        host.workers.select_map do |worker|
          next unless MixCheck.config.available_workers.include? worker.name
          {
            id: worker.pid, ppid: worker.ppid, name: worker.name, command: worker.cmdline,
            memory_size: worker.ram_used, inodes_count: worker.inodes_count,
            **worker.cpu.slice(:state, :nice, :threads, :start_time)
          }
        end
      end
    end
  end
end
