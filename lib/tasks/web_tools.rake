require_rel 'web_tools'

namespace :tools do
  desc 'symlink all private gems'
  task :symlink_all => :environment do
    # TODO
  end
end

namespace :test do
  desc 'run all tests in WebTools'
  task web_tools: "test:prepare" do
    WebTools::Runner.test_all
  end

  WebTools::Runner.testable_gems.each_key do |name|
    desc "run all tests in #{name.camelize}"
    task name => "test:prepare" do
      WebTools::Runner.test_all(name)
    end
  end
end
