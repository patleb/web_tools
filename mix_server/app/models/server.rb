class Server < LibMainRecord
  enum :provider, MixServer.config.available_providers

  def self.provisioned?(time = nil)
    ((time || Time.current) - current.created_at) > 10.minutes
  end

  def self.current
    @current ||= find_or_create_by!(
      private_ip: Process.host.private_ip,
      provider: Setting[:server_cluster_provider] || Setting[:cloud_provider]
    )
  end

  def self.update_private_ip!(private_ip, private_ip_was)
    return unless (server = find_by(private_ip: private_ip_was))
    server.update! private_ip: private_ip
  end
end
