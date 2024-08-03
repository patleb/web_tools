module ActionMailer::Interceptors
  class ForwardAllTo
    attr_reader :forward_to

    def initialize
      @forward_to = Setting[:mail_to]
    end

    def delivering_email(message)
      return if Rails.env.production?
      message.to = (forward_to.presence || message.to)
      message.cc = message.to if message.cc.present?
      message.bcc = message.to if message.bcc.present?
    end
    alias_method :previewing_email, :delivering_email
  end
end

interceptor = ActionMailer::Interceptors::ForwardAllTo.new
ActionMailer::Base.register_interceptor(interceptor)
ActionMailer::Base.register_preview_interceptor(interceptor)
