class SimpleJob < ApplicationJob
  include Minitest::Assertions

  delegate :assertions, :assertions=, to: :$test

  def perform(user, *args)
    assert_equal $test.args, [user, *args]
  end
end

module JobContext
  extend ActiveSupport::Concern

  included do
    self.use_transactional_tests = false

    let(:args){ [User::Null.new, { a: 1, b: 2.0, c: [{}.to_hwka] }] }
    let(:scheduled_at){ 5.minutes.from_now }

    around do |test|
      MixJob.with do |config|
        config.async = false
        test.call
      end
    end
  end

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::JobAdapter.new
  end
end
