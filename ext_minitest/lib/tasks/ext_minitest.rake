require_rel 'ext_minitest'

namespace :test do
  desc 'run all tests in WebTools'
  task web_tools: "test:prepare" do
    ExtMinitest::Runner.test_all
  end

  ExtMinitest::Runner.testable_gems.each_key do |name|
    desc "run all tests in #{name.camelize}"
    task name => "test:prepare" do
      ExtMinitest::Runner.test_all(name)
    end
  end
end
