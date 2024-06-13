module ActionMailer
  class SmtpSettings
    def initialize(settings)
      @_settings = settings
    end

    def merge(hash)
      settings.merge(hash)
    end

    def settings
      @settings ||= {
        authentication: 'login',
        enable_starttls_auto: true
      }.merge!((@_settings.respond_to?(:all) ? @_settings.all : @_settings).slice(*%i(
        mail_address
        mail_port
        mail_domain
        mail_username
        mail_password
        mail_authentication
        mail_enable_starttls_auto
      )).to_h.transform_keys!{ |key|
        key.to_s.sub(/^mail_/, '').sub('user', 'user_').to_sym
      })
    end
    alias_method :to_h, :settings
  end
end
