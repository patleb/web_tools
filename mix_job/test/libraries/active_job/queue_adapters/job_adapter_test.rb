require './test/test_helper'
require_relative './job_adapter_context'

module ActiveJob
  module QueueAdapters
    class JobAdapterTest < ActiveSupport::TestCase
      include JobAdapterContext

      test '#perform_now' do
        SimpleJob.any_instance.expects(:perform).with(*args).returns(:ok)
        SimpleJob.perform_now(*args)
      end

      context 'enqueued' do
        before do
          SimpleJob.any_instance.expects(:perform).never
        end

        test '#perform_later' do
          SimpleJob.perform_later(*args)
          assert Job.dequeue
        end

        test '#perform_later wait_until' do
          SimpleJob.set(wait_until: scheduled_at).perform_later(*args)
          travel_to 1.second.since(scheduled_at) do
            assert_equal scheduled_at.to_i, Job.dequeue.scheduled_at.to_i
          end
        end
      end
    end
  end
end
