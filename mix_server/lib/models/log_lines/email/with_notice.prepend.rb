module LogLines::Email::WithNotice
  extend ActiveSupport::Concern

  class_methods do
    def mailer(message)
      super || 'Notice'
    end
  end
end
