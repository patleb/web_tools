require 'rake/task'
require 'mix_task/rake/task/with_output'

Rake::Task.class_eval do
  prepend self::WithOutput

  def invoke!(*args)
    invoke(*args)
  ensure
    reenable
  end
end
