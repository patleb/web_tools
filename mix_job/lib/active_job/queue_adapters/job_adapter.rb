module ActiveJob
  module QueueAdapters
    class JobAdapter < AsyncAdapter
      def enqueue(job)
        return super if MixJob.config.async?
        job_data = job.serialize.to_hwka
        Job.enqueue job_data
      end

      def enqueue_at(job, timestamp)
        return super if MixJob.config.async?
        job_data = job.serialize.to_hwka.merge! scheduled_at: Time.at(timestamp)
        Job.enqueue job_data
      end

      if Rails.env.test?
        def enqueued_jobs
          @enqueued_jobs ||= []
        end

        def performed_jobs
          @performed_jobs ||= []
        end
      end
    end
  end
end
