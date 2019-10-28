module Rake
  module DSL
    def run_task(name, *args)
      Rake::Task[name].invoke(*args)
    end

    def run_task!(name, *args)
      Rake::Task[name].invoke!(*args)
    end

    def cap_task(stage, task, environment = {})
      environment = environment.each_with_object('RAILS_ENV=development') do |(name, value), string|
        string << " #{name.to_s.upcase}=#{value}"
      end
      cap = File.file?('bin/cap') ? 'bin/cap' : 'bundle exec cap'
      sh "#{environment} #{cap} #{stage} #{task}"
    end
  end
end
