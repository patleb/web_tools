options = {
  forward_emails_to: Class.new do
    def self.to_ary
      Class.new do
        def self.flatten
          Class.new do
            def self.uniq
              if defined?(Preference)
                if Preference.has_key? :mail_interceptors
                  Preference[:mail_interceptors]
                else
                  Preference[:mail_to]
                end
              else
                Setting[:mail_to]
              end
            end
          end
        end
      end
    end
  end
}

ActionMailer::Base.register_interceptor(MailInterceptor::Interceptor.new(options))
