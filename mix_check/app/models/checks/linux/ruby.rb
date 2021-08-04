module Checks
  module Linux
    class Ruby < WorkerGroup
      def self.list
        [inherited_group]
      end

      def pids_issue?
        minimum = MixServer.config.minimum_workers + Setting[:check_from_cron].to_i
        pids < minimum && host.uptime > (Setting[:check_interval] - 30.seconds)
      end
    end
  end
end
