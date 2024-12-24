namespace :tools do
  desc 'symlink all private gems'
  task :symlink_all => :environment do
    root = WebTools.root.join('lib_private')
    root.mkdir unless root.exist?
    root.children.select(&:symlink?).each(&:delete.with(false))
    WebTools.private_gems.each do |gem_name, gem_path|
      root.join(gem_name).symlink(gem_path, false)
    end
  end
end

namespace :test do
  testable_gems = WebTools.gems.merge(WebTools.private_gems).select{ |_name, path| path.join('test').exist? }

  desc 'run all tests in WebTools'
  task :web_tools do
    isolated_tests = testable_gems.each_with_object([{}]) do |(name, path), memo|
      path = path.join('test').to_s
      if WebTools.isolated_test_gems.include? name.to_s
        memo << { name => path }
      else
        memo.first[name] = path
      end
    end
    isolated_tests.each do |gems|
      Rails::TestUnit::Runner.run_from_rake 'test', gems.values
    end
  end

  testable_gems.each_key do |name|
    desc "run all tests in #{name.camelize}"
    task name do
      Rails::TestUnit::Runner.run_from_rake 'test', testable_gems[name].join('test').to_s
    end
  end
end
