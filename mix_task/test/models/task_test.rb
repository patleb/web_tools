require './test/test_helper'

class TaskTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  fixtures :users

  before do
    Task.delete_or_create_all
  end

  let!(:current_user) do
    Current.user = users(:admin)
  end
  let!(:session_id) do
    create_session!
  end
  let(:run_timeout){ 5 }
  let(:task){ Task.find(task_name) }
  let(:task_name){ 'try:send_email' }

  # NOTE self.use_transactional_tests == true --> task.run_callbacks :commit
  test '#perform_later' do
    run_and_assert_task

    assert task.notify_editable?
    task.update! notify: true

    assert_after{ LogLines::Email.where(subject: '[WebTools TEST] Healthcheck', sent: true).exists? }
    assert_after{ task.reload.success? }
    assert_until(sleep: 0.2) do
      LibMainRecord.uncached do
        LogLines::Email.where(subject: '[WebTools TEST] Notify', sent: true).exists?
      end
    end
    assert_flash notice: I18n.t('task.flash.success_html', path: task.path, name: task_name)
  end

  context '#perform_later' do
    let(:task_name){ 'try:raise_exception' }

    test 'with failure' do
      run_and_assert_task

      assert_after{ LogLines::Rescue.where(error: 'Rescues::RakeError').exists? }
      assert_until(sleep: 0.2){ task.reload.failure? }

      assert_flash alert: [I18n.t('task.flash.failure_html', path: task.path, name: task_name), 'Échec'].join('<br>- ')
    end
  end

  private

  def run_and_assert_task
    task.update! perform: true
    refute task.perform
    assert task.running?
    assert Task.running? task_name
    assert_raises ActiveRecord::RecordInvalid do
      task.update! perform: true
    end
  end

  def assert_flash(**messages)
    flash_messages = {}
    Flash.dequeue_in(flash_messages)
    assert_equal(messages, flash_messages)
  end
end
