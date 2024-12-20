MonkeyPatch.add{['activejob', 'lib/active_job/execution.rb', '4f59c2db707c74ef937cc033a5f1179a9d52951b09484e422681be203fd8cbda']}

ActiveJob::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun

  private

  def _perform_job
    ActiveSupport::ExecutionContext[:job] = self
    run_callbacks :perform do
      options = arguments.extract_options!
      perform(*arguments, **options)
    end
  end
end
