require 'rake/task'
require 'ext_rails/rake/task/with_output'

Rake::Task.class_eval do
  def invoke!(...)
    reenable if @already_invoked
    invoke(...)
  ensure
    reenable
  end
end
