require './test/test_helper'

class LibMailerTest < ActionMailer::TestCase
  self.use_transactional_tests = false

  it 'should send healthcheck email' do
    email = Setting.with(freeze:false) do |settings|
      settings[:mail_to] = 'example@test.com'
      assert_equal Setting[:mail_to], 'example@test.com'
      email = LibMailer.healthcheck
      assert_emails(1){ email.deliver_now }
      email
    end
    assert_equal [Setting[:mail_from]], email.from
    refute_equal Setting[:mail_to], 'example@test.com'
    assert_equal Setting[:mail_to], email.to
    assert_equal '[WebTools TEST] Healthcheck', email.subject
    assert_equal 'ok', email.text_part.body.to_s
  end
end
