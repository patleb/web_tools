module Monits
  module Linux
    class Socket < Base
      alias_attribute :inode, :id
      attribute       :pid, :integer
      attribute       :tcp, :boolean
      attribute       :local_ip
      attribute       :local_port, :integer
      attribute       :remote_ip
      attribute       :remote_port, :integer
      attribute       :state
      attribute       :command

      def self.list
        sockets = host.sockets(pid: false)
        pids = host.inodes.each_with_object({}) do |(inode, pid), memo|
          (memo[pid] ||= Set.new) << inode if sockets.has_key? inode
        end
        sockets.map do |inode, socket|
          pid = pids.find{ |_, v| v.include? inode }&.first
          worker = Process::Worker.new(pid) if pid
          {
            id: inode, pid: pid, tcp: socket[0] == :tcp,
            local_ip: socket[1], local_port: socket[2], remote_ip: socket[3], remote_port: socket[4],
            state: socket[5].to_s, command: worker&.cmdline
          }
        end
      end
    end
  end
end
