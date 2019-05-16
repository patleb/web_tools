module Rake
  module DSL
    def write(dst, value, verbose: true)
      Rake.rake_output_message "write #{dst}" if verbose
      Pathname.new(dst).write(value)
    end

    def app_name
      Rails.application.name
    end

    def app_secret
      SecureRandom.hex(64)
    end

    def generate_password
      SecureRandom.hex(16)
    end
  end
end
