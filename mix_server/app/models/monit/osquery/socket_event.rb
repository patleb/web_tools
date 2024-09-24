# frozen_string_literal: true

module Monit
  module Osquery
    class SocketEvent < Base
      attribute :pid, :integer
      attribute :time, :datetime
      attribute :local_ip
      attribute :local_port, :integer
      attribute :remote_ip
      attribute :remote_port, :integer
      attribute :connected, :boolean
      attribute :path
      attribute :end, :boolean

      def self.list
        (osquery['socket_events'] || []).flat_map do |events|
          events.select_map do |state, rows|
            rows.map do |row|
              pid, time, remote_ip, remote_port = row.values_at('pid', 'time', 'remote_address', 'remote_port')
              {
                id: [pid, time, remote_ip, remote_port].join(':'), pid: pid, time: Time.at(time).utc,
                local_ip: row['local_address'], local_port: row['local_port'],
                remote_ip: remote_ip, remote_port: remote_port,
                connected: %w(connect bind).include?(row['action']),
                path: row['cmdline'],
                end: state == :old
              }
            end
          end
        end
      end
    end
  end
end
