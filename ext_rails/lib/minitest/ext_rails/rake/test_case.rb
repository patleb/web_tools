module Rake
  class TestCase < ActiveSupport::TestCase
    Rails.application.load_tasks

    class_attribute :task_namespace
    class_attribute :task_name, instance_predicate: false, instance_accessor: false

    attr_accessor :result

    protected

    def run_task(*args, **argv)
      Rake::DSL.with_argv(task_name, **argv) do
        Rake::Task[task_name].invoke!(*args)
      end
    end

    def task_name
      return self.class.task_name if self.class.task_name.present?
      namespace = "#{task_namespace}:" if task_namespace.present?
      "#{namespace}#{base_name.sub(/^(Mix|Ext)([A-Z])/, '\2').sub(/Task$/, '').underscore.tr('/', ':')}"
    end

    def teardown
      self.result = nil
      super
    end
  end
end
