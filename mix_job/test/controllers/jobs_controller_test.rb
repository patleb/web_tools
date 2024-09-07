require './test/test_helper'
require './mix_job/test/support/job_context'

class JobsControllerTest < ActionDispatch::IntegrationTest
  include JobContext

  test '#create' do
    SimpleJob.perform_later(*args)
    job = Job.dequeue

    post job.url, params: { job: job.data }, as: :json

    assert_response :created
  end

  test '#create with exception' do
    post Job.url(job_class: 'SimpleJob', job_id: 'h'), as: :json

    assert_response :job_server_error
    assert_equal true, LogMessage.where('text_tiny LIKE ?', '%ActionController::ParameterMissing%').take.reported?
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test '#create with bad params' do
    SimpleJob.perform_later(*args)
    job = Job.dequeue

    post job.url, params: { job: job.data.except(:job_id) }, as: :json

    assert_response :job_client_error
    assert_equal true, LogMessage.where('text_tiny LIKE ?', '%ActiveRecord::RecordInvalid%').take.reported?
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
end
