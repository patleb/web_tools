MonkeyPatch.add{['activejob', 'lib/active_job/execution.rb', 'ff5c0d33d2718d2a6d7d6a9e5df8a2cd89bdc8871bb8c36e44bad2433dd19008']}

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
