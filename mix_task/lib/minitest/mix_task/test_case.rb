module Rake
  class TestCase < ActiveSupport::TestCase
    require 'rake'
    Rails.application.all_rake_tasks

    class_attribute :task_namespace

    protected

    def run_task(*args, **argv)
      Rake::DSL.with_argv(task_name, **argv) do
        Rake::Task[task_name].invoke!(*args)
      end
    end

    def task_name
      if task_namespace.present?
        namespace = "#{task_namespace}:"
      end
      "#{namespace}#{base_name.sub(/^(Mix|Ext)([A-Z])/, '\2').sub(/Task$/, '').underscore.tr('/', ':')}"
    end
  end
end
