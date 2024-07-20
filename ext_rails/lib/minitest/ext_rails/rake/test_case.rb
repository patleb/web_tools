module Rake
  class TestCase < ActiveSupport::TestCase
    Rails.application.load_tasks

    class_attribute :task_name, instance_predicate: false, instance_writer: false

    attr_accessor :result

    protected

    def run_task(*args, **argv)
      Rake::DSL.with_argv(task_name, **argv) do
        Rake::Task[task_name].invoke!(*args)
      end
    end

    def teardown
      self.result = nil
      super
    end
  end
end
