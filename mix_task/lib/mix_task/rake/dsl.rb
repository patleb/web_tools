module Rake
  module DSL
    def run_task(task_name, *args)
      Rake::Task[task_name].invoke(*args)
    end

    def run_task!(task_name, *args)
      Rake::Task[task_name].invoke!(*args)
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
