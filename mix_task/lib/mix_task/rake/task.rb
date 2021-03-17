require 'rake/task'
require 'mix_task/rake/task/with_output'

Rake::Task.class_eval do
  prepend self::WithOutput

  def invoke!(...)
    reenable if @already_invoked
    invoke(...)
  ensure
    reenable
  end
end
