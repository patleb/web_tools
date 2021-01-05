class EmailRecord
  class Interceptor
    def self.delivering_email(message)
      Log.email(message)
    end
  end

  class Observer
    def self.delivered_email(message)
      Log.email(message, sent: true)
    end
  end
end

ActionMailer::Base.register_interceptor(EmailRecord::Interceptor)
ActionMailer::Base.register_observer(EmailRecord::Observer)
