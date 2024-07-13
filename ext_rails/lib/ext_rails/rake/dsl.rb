module Rake
  STARTED = '[STARTED]'
  SUCCESS = '[SUCCESS]'
  FAILURE = '[FAILURE]'
  STEP    = '[STEP]'
  CANCEL  = '[CANCEL]'
  RUNNING = '[RUNNING]'

  module DSL
    def with_argv(task_name, **argv)
      if argv.any?
        old_argv = ARGV.dup
        ARGV.replace([task_name, '--'])
        argv.each do |key, value|
          ARGV << case value
          when nil, true  then "--#{key.to_s.dasherize}"
          when false      then "--no-#{key.to_s.dasherize}"
          when Array, Set then "--#{key.to_s.dasherize}=#{value.to_a.join(',')}"
          else                 "--#{key.to_s.dasherize}=#{value}"
          end
        end
      end
      yield
    ensure
      ARGV.replace(old_argv) if old_argv
    end
    module_function :with_argv

    def run_task(task_name, *args, **argv)
      with_argv(task_name, **argv) do
        Rake::Task[task_name].invoke(*args)
      end
    end

    def run_task!(task_name, *args, **argv)
      with_argv(task_name, **argv) do
        Rake::Task[task_name].invoke!(*args)
      end
    end
  end
end
