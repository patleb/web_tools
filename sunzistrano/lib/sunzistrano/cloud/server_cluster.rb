module Cloud::ServerCluster
  class UnsupportedClusterProvider < ::StandardError; end

  def server_cluster_master
    if Setting[:server_cluster_master_ip].present?
      Setting[:server_cluster_master_ip]
    else
      case Setting[:server_cluster_provider]
      when 'vagrant'   then vagrant_server_ips(Setting[:server_host]).first
      when 'openstack' then openstack_server_ips(Setting[:server_cluster_master], 'ACTIVE').first
      else raise UnsupportedClusterProvider
      end
    end
  end

  def server_cluster_ips
    if Setting[:server_cluster_ips].present?
      Setting[:server_cluster_ips]
    else
      server_cluster.values
    end
  end

  def server_cluster # TODO run_locally --> so Openstack credentials don't need to be shared
    case Setting[:server_cluster_provider]
    when 'vagrant'   then vagrant_servers(Setting[:server_cluster_name])
    when 'openstack' then openstack_servers(Setting[:server_cluster_name], 'ACTIVE')
    else raise UnsupportedClusterProvider
    end
  end
end
