module Rake
  class TestCase < ActiveSupport::TestCase
    require 'rake'
    Rails.application.all_rake_tasks

    class_attribute :task_namespace

    protected

    def run_task(*args, **argv)
      Rake::Task[task_name].reenable
      if argv.any?
        ARGV << task_name
        ARGV << '--'
        argv.each do |key, value|
          ARGV <<
            case value
            when nil, true
              "--#{key.to_s.dasherize}"
            when false
              "--no-#{key.to_s.dasherize}"
            else
              "--#{key.to_s.dasherize}=#{value}"
            end
        end
      end
      Rake::Task[task_name].invoke(*args)
    end

    def task_name
      if task_namespace.present?
        namespace = "#{task_namespace}:"
      end
      "#{namespace}#{base_name.sub(/^(Mr|Ext)([A-Z])/, '\2').sub(/Task$/, '').underscore.tr('/', ':')}"
    end
  end
end
