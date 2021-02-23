require './test/rails_helper'
require './mix_job/test/libraries/active_job/queue_adapters/job_adapter_context'

class JobsControllerTest < ActionDispatch::IntegrationTest
  include JobAdapterContext

  delegate :jobs_url, to: 'Rails.application.routes.url_helpers'

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::JobAdapter.new
  end

  describe '#perform' do
    before do
      ActionMailer::Base.deliveries.clear
    end

    it 'should succeed' do
      SimpleJob.perform_later(*args)
      job = Job.dequeue

      post job.url, params: { job: job.data }, as: :json

      assert_response :created
    end

    it 'should handle exceptions' do
      post Job.url, as: :json

      assert_response :job_server_error
      assert_equal true, LogMessage.where('text_tiny LIKE ?', '%ActionController::ParameterMissing%').take.alerted?
      assert_equal 1, ActionMailer::Base.deliveries.size
    end

    it 'should handle bad params' do
      SimpleJob.perform_later(*args)
      job = Job.dequeue

      post job.url, params: { job: job.data.except(:job_id) }, as: :json

      assert_response :job_client_error
      assert_equal true, LogMessage.where('text_tiny LIKE ?', '%ActiveRecord::RecordInvalid%').take.alerted?
      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end
end
