module Monit
  module Osquery
    class Heartbeat < Base
      attribute :pid, :integer
      attribute :watcher_pid, :integer
      attribute :time, :datetime
      attribute :configured, :boolean
      attribute :ram, :integer

      def self.list
        (osquery['osquery_info'] || []).flat_map do |rows|
          time = rows[:time]
          rows[:new].map do |row|
            pid = row['pid']
            {
              id: [pid, time].join(':'), pid: pid, watcher_pid: row['watcher'],
              configured: row['config_valid'], time: Time.at(time).utc,
              ram: row['resident_size']
            }
          end
        end
      end
    end
  end
end
