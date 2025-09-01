require_dir __FILE__, 'cloud'

module Cloud
  class << self
    delegate :master_ip,
      to: 'Cloud::Base.build(Setting[:cloud_provider])'
    delegate :cluster_ips, :cluster_paths,
      to: 'Cloud::Base.build(Setting[:server_cluster_provider] || Setting[:cloud_provider])'
  end

  def self.server_ips
    [master_ip] + cluster_ips
  end
end
