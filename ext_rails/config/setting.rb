Setting.class_eval do
  def self.default_url_options
    case @env.to_sym
    when :development
      { host: self[:server_host], port: self[:server_port] }
    when :test
      { host: '127.0.0.1', port: 3333 }
    else
      { host: self[:server_host] }
    end
  end

  def self.server
    [self[:server_host], self[:server_port]].compact.join(':')
  end

  def self.smtp
    slice(*%i(
      mail_address
      mail_port
      mail_domain
      mail_username
      mail_password
      mail_authentication
      mail_enable_starttls_auto
    )).to_h.compact.transform_keys!{ |key|
      key.to_s.sub(/^mail_/, '').sub('user', 'user_').to_sym
    }
  end
end
