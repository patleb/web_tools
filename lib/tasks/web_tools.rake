require_dir __FILE__, 'web_tools'

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
