class MainMailerJob < ActionMailer::MailDeliveryJob
  def perform(mailer, mail_method, delivery_method, options = {})
    super(mailer, mail_method, delivery_method, **options)
  end
end
