module Monit
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
      attribute       :ram, :integer
      attribute       :inodes, :integer

      def self.list
        host.workers.select_map do |worker|
          next unless MixServer.config.available_workers.include? worker.name
          {
            id: worker.pid, ppid: worker.ppid, name: worker.name, command: worker.cmdline,
            **worker.cpu.slice(:state, :nice, :threads, :start_time),
            ram: worker.ram_used, inodes: worker.inodes_count,
          }
        end
      end
    end
  end
end
