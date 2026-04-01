module Monit
  module Osquery
    class Monitor < Base
      nests_many :threats,       default: proc { Threat.all }
      nests_many :heartbeats,    default: proc { Heartbeat.all }
      nests_many :file_events,   default: proc { FileEvent.all }
      nests_many :socket_events, default: proc { SocketEvent.all }

      validates :threats, absence: true
      validates :heartbeats, presence: true

      def self.list
        [{ id: 'monitor' }]
      end
    end
  end
end
