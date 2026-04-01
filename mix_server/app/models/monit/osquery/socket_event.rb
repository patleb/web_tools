module Monit
  module Osquery
    NO_IP_OR_PORT = '0' # https://github.com/osquery/osquery/pull/8510/changes

    class SocketEvent < Base
      attribute :pid, :integer
      attribute :time, :datetime
      attribute :local_ip
      attribute :local_port, :integer
      attribute :remote_ip
      attribute :remote_port, :integer
      attribute :connected, :boolean
      attribute :path
      attribute :old, :boolean

      def self.list
        (osquery['socket_events'] || []).flat_map do |events|
          events.except(:time).flat_map do |state, rows|
            rows.map do |row|
              pid, time, action, cmdline = row.values_at('pid', 'time', 'action', 'cmdline')
              addresses = row.values_at('local_address', 'local_port', 'remote_address', 'remote_port')
              local_ip, local_port, remote_ip, remote_port = addresses.map{ |v| v.blank? ? NO_IP_OR_PORT : v }
              {
                id: [pid, time, remote_ip, remote_port].join(':'), pid: pid, time: Time.at(time).utc,
                local_ip: local_ip, local_port: local_port,
                remote_ip: remote_ip, remote_port: remote_port,
                connected: %w(connect bind).include?(action),
                path: cmdline,
                old: state == :old
              }
            end
          end
        end
      end
    end
  end
end
