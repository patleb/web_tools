module ActiveJob
  module QueueAdapters
    class JobAdapter
      def enqueue(job)
        job_data = job.serialize.symbolize_keys!
        Job.enqueue job_data
      end

      def enqueue_at(job, timestamp)
        job_data = job.serialize.symbolize_keys!.merge! scheduled_at: Time.at(timestamp)
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
