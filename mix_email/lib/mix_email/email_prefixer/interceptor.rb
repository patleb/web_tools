module EmailPrefixer
  class Interceptor
    attr_accessor :application_name
    attr_accessor :stage_name

    def initialize(application_name, stage_name)
      @application_name = application_name.camelize
      @stage_name = stage_name.upcase
    end

    def delivering_email(mail)
      mail.subject.prepend(prefix)
    end
    alias_method :previewing_email, :delivering_email

    private

    def prefix
      stage_name = self.stage_name
      prefixes = []
      prefixes << self.application_name
      prefixes << stage_name unless stage_name == 'production'
      "[#{prefixes.join(' ')}] "
    end
  end
end

interceptor = EmailPrefixer::Interceptor.new(Rails.app, Rails.env)
ActionMailer::Base.register_interceptor(interceptor)
ActionMailer::Base.register_preview_interceptor(interceptor)
