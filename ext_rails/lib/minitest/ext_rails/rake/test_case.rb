module Rake
  class TestCase < ActiveSupport::TestCase
    include ActionMailer::TestHelper
    include ActionMailer::TestCase::ClearTestDeliveries

    Rails.application.load_tasks

    class_attribute :task_name, instance_predicate: false, instance_writer: false

    attr_accessor :result

    protected

    def run_rake(*args, as: task_name, **argv)
      Rake::DSL.with_argv(as, **argv) do
        Rake::Task[as].invoke!(*args)
      end
    end

    def teardown
      self.result = nil
      super
    end
  end
end
