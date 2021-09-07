require './test/rails_helper'
require_relative './job_adapter_context'

module ActiveJob
  module QueueAdapters
    class JobAdapterTest < ActiveSupport::TestCase
      include JobAdapterContext

      around do |test|
        MixJob.with do |config|
          config.async = false
          test.call
        end
      end

      describe '#perform_now' do
        before do
          SimpleJob.any_instance.expects(:perform).with(*args).returns(:ok)
        end

        it 'should perform' do
          SimpleJob.perform_now(*args)
        end
      end

      describe '#perform_later' do
        context 'later' do
          before do
            SimpleJob.any_instance.expects(:perform).never
          end

          it 'should enqueue locally' do
            SimpleJob.perform_later(*args)
            assert Job.dequeue
          end

          it 'should enqueue at globally' do
            SimpleJob.set(wait_until: scheduled_at).perform_later(*args)
            travel_to 1.second.since(scheduled_at) do
              assert_equal scheduled_at.to_i, Job.dequeue.scheduled_at.to_i
            end
          end
        end
      end
    end
  end
end
