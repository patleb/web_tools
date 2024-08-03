require './test/test_helper'

class LibMailerTest < ActionMailer::TestCase
  self.use_transactional_tests = false

  it 'should send healthcheck email' do
    email = LibMailer.healthcheck
    assert_emails(1){ email.deliver_now }
    assert_equal [Setting[:mail_from]], email.from
    assert_equal Setting[:mail_to], email.to
    assert_equal 'Healthcheck', email.subject
    assert_equal 'ok', email.text_part.body.to_s
  end
end
