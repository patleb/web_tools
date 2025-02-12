namespace :test do
  testable_gems = WebTools.gems.merge(WebTools.private_gems).select{ |_name, path| path.join('test').exist? }
  minitest_gems = testable_gems.select{ |_name, path| path.glob('test/**/*_test.rb').first.read.include? 'test/spec_helper' }

  desc 'run all tests for WebTools'
  task :web_tools do
    isolated_tests = testable_gems.each_with_object([{}, {}]) do |(name, path), memo|
      path = path.join('test').to_s
      if WebTools.isolated_test_gems.include? name.to_s
        memo.insert 1, { name => path }
      elsif minitest_gems.has_key? name.to_s
        memo.first[name] = path
      else
        memo.last[name] = path
      end
    end
    isolated_tests.compact_blank.each do |gems|
      puts "run all tests for: #{gems.keys.map(&:camelize).sort.join(', ')}"
      Rails::TestUnit::Runner.run_from_rake 'test', gems.values
    end
  end

  testable_gems.each_key do |name|
    desc "run all tests for #{name.camelize}"
    task name do
      Rails::TestUnit::Runner.run_from_rake 'test', testable_gems[name].join('test').to_s
    end
  end
end
