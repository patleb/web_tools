require './test/rails_helper'
require_relative './task_job_context'

class TaskJobTest < ActiveJob::TestCase
  include TaskJobContext

  it 'should succeed with send_email task' do
    Current.user = users(:admin)
    assert_emails(1) do # NOTE the email sent by the task isn't this one since it belongs to the child process
      TaskJob.perform_now('try:send_email')
    end
    assert_equal true, email_task.success?
  end

  it 'should fail with raise_exception task' do
    Current.user = users(:normal)
    assert_emails(1) do
      TaskJob.perform_now('try:raise_exception')
    end
    assert_equal true, raise_task.failure?
  end
end
