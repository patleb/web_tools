require './test/rails_helper'

class MainMailerTest < ActionMailer::TestCase
  it 'should send healthcheck email and log events' do
    subject = 'Healthcheck'
    email = MainMailer.healthcheck
    assert_emails(1){ email.deliver_now }
    assert_equal [Setting[:mail_from]], email.from
    assert_equal Setting[:mail_to], email.to
    assert_equal subject, email.subject
    assert_equal 'ok', email.text_part.body.to_s
    assert_equal 2, LogLines::Email.where(subject: subject).size
    assert_equal 1, LogLines::Email.where(subject: subject, sent: true).size
  end
end
