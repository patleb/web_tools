module Checks
  module Linux
    class Ruby < WorkerGroup
      def self.list
        [inherited_group]
      end

      def pids_issue?
        pids < MixServer.config.minimum_workers
      end
    end
  end
end
