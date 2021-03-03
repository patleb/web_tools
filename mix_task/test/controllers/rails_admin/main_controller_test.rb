require './test/rails_helper'
require_relative '../../jobs/task_job_context'

module RailsAdmin
  class MainControllerTest < ActionDispatch::IntegrationTest
    include TaskJobContext

    attr_accessor :session_id

    let(:notify){ false }
    let(:user){ users(:deployer) }

    before do
      ENV['DEVISE_USER'] = user.email
    end

    it 'should run the task correctly' do
      assert_enqueued_with(job: TaskJob) do
        put rails_admin.edit_url(model_name: 'task', id: 'try:send_email'), params: { task: { notify: '1', _perform: '1' }, _save: '' }
      end
      task = Task.find('try:send_email')
      assert_equal true, task.running?
      assert_equal true, session[:flash_later]
      $test.session_id = session.id

      put rails_admin.edit_path(model_name: 'task', id: 'try:send_email'), params: { task: { notify: '0', _perform: '1' }, _save: '' }
      assert_response :not_acceptable
      assert_equal true, flash[:error].present?
      assert_equal true, session[:flash_later]

      perform_enqueued_jobs
      get rails_admin.edit_path(model_name: 'task', id: 'try:send_email')
      assert_equal true, flash[:alert].present?
      assert_nil session[:flash_later]
    end
  end
end
