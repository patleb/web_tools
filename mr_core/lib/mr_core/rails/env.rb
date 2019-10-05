module Rails
  module Env
    def self.dev_or_test?
      return @dev_or_test if defined? @dev_or_test
      @dev_or_test = Rails.env.development? || Rails.env.test?
    end

    def self.dev_or_vagrant?
      return @dev_or_vagrant if defined? @dev_or_vagrant
      @dev_or_vagrant = Rails.env.development? || (Rails.env.vagrant? && ENV['DEVELOPMENT'].to_b)
    end

    def self.dev_ngrok?
      return @ngrok if defined? @ngrok
      @ngrok = Rails.env.development? && ENV['NGROK'].present?
    end

    def self.dev_rack_profiling?
      return @dev_rack_profiling if defined? @dev_rack_profiling
      @dev_rack_profiling =
        defined?(::Rack::Lineprof) \
        && Rails.application.middleware.include?(::Rack::Lineprof) \
        && Rails.env.development?
    end

    def self.dev_or_test_url_options
      host, port =
        case Rails.env.to_sym
        when :development
          if dev_ngrok?
            ["#{ENV['NGROK']}.ngrok.io", nil]
          else
            ['localhost', 3000]
          end
        when :test
          ['127.0.0.1', 3333]
        end
      { host: host, port: port }
    end
  end
end
