module ActionMailer::LogSubscriber::WithQuietInfo
  def deliver(event)
    info do
      recipients = Array(event.payload[:to]).join(", ")
      "Sent mail to #{recipients} (#{event.duration.round(1)}ms)"
    end
  end
end

ActionMailer::LogSubscriber.prepend ActionMailer::LogSubscriber::WithQuietInfo
