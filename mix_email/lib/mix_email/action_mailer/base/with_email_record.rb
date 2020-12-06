class EmailRecord
  class Interceptor
    def self.delivering_email(message)
      Email.create_from_header! message
    end
  end

  class Observer
    def self.delivered_email(message)
      email = Email.find_by_header! message
      email.update! sent: true
    end
  end
end

ActionMailer::Base.register_interceptor(EmailRecord::Interceptor)
ActionMailer::Base.register_observer(EmailRecord::Observer)
