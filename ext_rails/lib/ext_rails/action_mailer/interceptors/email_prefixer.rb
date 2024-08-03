module ActionMailer::Interceptors
  class EmailPrefixer
    attr_reader :prefix

    def initialize
      @prefix = "[#{Rails.app.camelize} #{Rails.env.upcase}] "
    end

    def delivering_email(mail)
      return if Rails.env.production?
      mail.subject.prepend(prefix)
    end
    alias_method :previewing_email, :delivering_email
  end
end

interceptor = ActionMailer::Interceptors::EmailPrefixer.new
ActionMailer::Base.register_interceptor(interceptor)
ActionMailer::Base.register_preview_interceptor(interceptor)
