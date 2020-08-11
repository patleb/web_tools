require_rel 'ext_minitest'

namespace :ext_minitest do
  desc 'setup ExtMinitest files'
  task :setup do
    src, dst = Gem.root('ext_minitest').join('lib/tasks/templates'), Rails.root

    ['test/rails_helper.rb', 'test/spec_helper.rb'].each do |file|
      cp src/file, dst/file
    end

    remove dst/'test/test_helper.rb' rescue nil
    keep   dst/'test/cassettes'
  end
end

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
