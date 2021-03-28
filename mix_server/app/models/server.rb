class Server < LibMainRecord
  enum provider: MixServer.config.available_providers

  def self.current
    @current ||= find_or_create_by! private_ip: Process.host.private_ip, provider: Setting[:server_provider]
  end
end
