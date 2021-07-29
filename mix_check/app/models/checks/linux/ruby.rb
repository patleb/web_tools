module Checks
  module Linux
    class Ruby < WorkerGroup
      def self.list
        [inherited_group]
      end

      def pids_issue?
        pids < MixServer.config.minimum_workers && host.uptime > (Setting[:check_interval] - 30.seconds)
      end
    end
  end
end
