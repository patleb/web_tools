Setting.class_eval do
  def self.default_url_options
    case @env.to_sym
    when :development
      if Rails.env.dev_ngrok?
        { host: "#{ENV['NGROK']}.ngrok.io" }
      else
        { host: self[:server_host], port: self[:server_port] }
      end
    when :test
      { host: '127.0.0.1', port: 3333 }
    else
      { host: self[:server_host] }
    end
  end

  def self.server
    [self[:server_host], self[:server_port]].compact.join(':')
  end
end
