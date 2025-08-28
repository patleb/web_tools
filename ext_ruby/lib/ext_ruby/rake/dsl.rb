module Rake
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

    def namespace!(name = nil, &block)
      module_name  = "#{name.to_s.camelize}_Tasks"
      with_scope   = self.class.const_get(module_name) if self.class.const_defined? module_name
      with_scope ||= self.class.const_set(module_name, Module.new)
      with_scope.module_eval do
        extend Rake::DSL
        extend self
        namespace name do
          instance_eval(&block)
        end
      end
    end

    def flag_on?(args, name)
      return unless args.respond_to? :key?
      value = args[name]
      (value.to_s == name.to_s) || value.to_b
    end
  end
end
