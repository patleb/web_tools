require './test/test_helper'

class ActionMailer::BaseTest < ActionMailer::TestCase
  self.use_transactional_tests = false

  it 'should log email events' do
    LibMailer.healthcheck.deliver_now
    assert_equal 2, LogLines::Email.where(subject: 'Healthcheck').size
    assert_equal 1, LogLines::Email.where(subject: 'Healthcheck', sent: true).size
  end
end
