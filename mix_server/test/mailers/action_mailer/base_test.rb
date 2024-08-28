require './test/test_helper'

class ActionMailer::BaseTest < ActionMailer::TestCase
  self.use_transactional_tests = false

  test 'Log.email' do
    LibMailer.healthcheck.deliver_now
    assert_equal 2, LogLines::Email.where(subject: '[WebTools TEST] Healthcheck').size
    assert_equal 1, LogLines::Email.where(subject: '[WebTools TEST] Healthcheck', sent: true).size
  end
end
