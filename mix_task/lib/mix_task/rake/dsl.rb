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

    def cap_task(task_name, environment = {})
      environment = environment.with_keyword_access
      stage = [environment.delete(:env).presence || Rails.env, environment.delete(:app)].compact.join(':')
      environment = environment.each_with_object('RAILS_ENV=development') do |(name, value), string|
        string << " #{name.to_s.upcase}=#{value}"
      end
      cap = File.file?('bin/cap') ? 'bin/cap' : 'bundle exec cap'
      sh "#{environment} #{cap} #{stage} #{task_name}"
    end
  end
end
