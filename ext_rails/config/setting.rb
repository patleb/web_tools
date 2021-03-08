Setting.class_eval do
  def self.default_url_options
    case Rails.env.to_sym
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

  def self.database_url(user = self[:db_username], pwd = self[:db_password])
    "postgresql://#{user}:#{pwd}@#{self[:db_host] || '127.0.0.1'}:#{self[:db_port] || 5432}/#{self[:db_database]}"
  end

  def self.server
    [self[:server_host], self[:server_port]].compact.join(':')
  end
end
