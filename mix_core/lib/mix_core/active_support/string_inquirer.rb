ActiveSupport::StringInquirer.class_eval do
  def dev_or_test?
    return @dev_or_test if defined? @dev_or_test
    @dev_or_test = development? || test?
  end

  def dev_or_vagrant?
    return @dev_or_vagrant if defined? @dev_or_vagrant
    @dev_or_vagrant = development? || (vagrant? && ENV['DEVELOPMENT'].to_b)
  end

  def dev_ngrok?
    return @ngrok if defined? @ngrok
    @ngrok = development? && ENV['NGROK'].present?
  end

  def dev_or_test_url_options
    host, port =
      case to_sym
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
