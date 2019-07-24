module ActionMailer
  class SmtpSettings
    def initialize(settings)
      @_settings = settings
    end

    def merge(hash)
      settings.merge(hash)
    end

    def settings
      @settings ||= (@_settings.respond_to?(:all) ? @_settings.all : @_settings).slice(*%i(
        mail_address
        mail_port
        mail_domain
        mail_username
        mail_password
      )).to_h.transform_keys!{ |key|
        key.to_s.sub(/^mail_/, '').to_sym
      }.merge!(
        authentication: :plain,
        enable_starttls_auto: true
      )
    end
  end
end
