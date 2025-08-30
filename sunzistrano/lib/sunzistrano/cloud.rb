require_dir __FILE__, 'cloud'

module Cloud
  class << self
    delegate :server_master,
      to: 'Cloud::Base.build(Setting[:server_provider])'
    delegate :server_cluster_list, :server_cluster_ips, :server_cluster_paths,
      to: 'Cloud::Base.build(Setting[:server_cluster_provider] || Setting[:server_provider])'
  end

  def self.servers
    [server_master] + server_cluster_ips
  end
end
