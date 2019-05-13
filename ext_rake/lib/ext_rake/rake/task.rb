require 'rake/task'
require 'ext_rake/rake/task/with_output'

Rake::Task.class_eval do
  include ActionView::Helpers::DateHelper
  prepend self::WithOutput

  def invoke!(*args)
    invoke(*args)
  ensure
    reenable
  end
end
