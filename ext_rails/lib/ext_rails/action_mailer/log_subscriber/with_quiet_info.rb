MonkeyPatch.add{['actionmailer', 'lib/action_mailer/log_subscriber.rb', '5a98a9a5f8f8a62f44b6dc3129bcf7df764b12cc5c31537abf62b73221195e05']}

module ActionMailer::LogSubscriber::WithQuietInfo
  def deliver(event)
    return super if ExtRails.config.email_debug
    info do
      recipients = Array(event.payload[:to]).join(", ")
      "Sent mail to #{recipients} (#{event.duration.round(1)}ms)"
    end
  end
end

ActionMailer::LogSubscriber.prepend ActionMailer::LogSubscriber::WithQuietInfo
