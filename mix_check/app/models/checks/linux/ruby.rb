module Checks
  module Linux
    class Ruby < WorkerGroup
      def self.list
        [inherited_group]
      end

      def pids_issue?
        if Rails.configuration.active_job.queue_adapter == :job && !MixJob.config.async?
          pids <= 2
        else
          pids <= 1 # must skip the current process
        end
      end
    end
  end
end
