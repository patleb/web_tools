# Add your own tasks in files placed in app/tasks ending in .rake,
# for example app/tasks/example.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

if (path = ENV['TEST_VALGRIND']).present? && File.exist?(path)
  require "ruby_memcheck"

  namespace :test do
    RubyMemcheck::TestTask.new :valgrind do |t|
      t.test_files = [path]
    end
  end
end
