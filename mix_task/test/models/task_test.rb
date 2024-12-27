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
  let(:run_timeout){ 10 }

  # NOTE self.use_transactional_tests == true --> task.run_callbacks :commit
  test '#perform_later' do
    task = run_and_assert_task 'try:send_email'
    assert task.notify_editable?
    task.update! notify: true
    assert_after{ LogLines::Email.where(subject: '[WebTools TEST] Healthcheck', sent: true).exists? }
    assert_after{ task.reload.success? }
    assert_until(sleep: 0.2) do
      LibMainRecord.uncached do
        LogLines::Email.where(subject: '[WebTools TEST] Notify', sent: true).exists?
      end
    end
    assert_flash notice: I18n.t('task.flash.success_html', path: task.path, name: task.name)

    task = run_and_assert_task 'try:raise_exception'
    assert_after{ LogLines::Rescue.where(error: 'Rescues::RakeError').exists? }
    assert_until(sleep: 0.2){ task.reload.failure? }
    assert_flash alert: [I18n.t('task.flash.failure_html', path: task.path, name: task.name), 'Échec'].join('<br>- ')
  end

  private

  def run_and_assert_task(name)
    task = Task.find(name)
    task.update! perform: true
    refute task.perform
    assert task.running?
    assert Task.running? task.name
    assert_raises ActiveRecord::RecordInvalid do
      task.update! perform: true
    end
    task
  end

  def assert_flash(**messages)
    flash_messages = {}
    Flash.dequeue_in(flash_messages)
    assert_equal(messages, flash_messages)
  end
end
