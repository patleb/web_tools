module Cloud::ServerCluster
  class UnsupportedClusterProvider < ::StandardError; end

  def servers
    [Cloud.server_master] + Cloud.server_cluster_ips
  end

  def server_master
    @server_master ||= if Setting.rails_env? :development, :test
      '127.0.0.1'
    elsif Setting[:server_master_ip].present?
      Setting[:server_master_ip]
    else
      case Setting[:server_cluster_provider]
      when 'vagrant'   then vagrant_server_ips(Setting[:server_host]).first
      when 'openstack' then openstack_server_ips(Setting[:server_master_name], 'ACTIVE').first
      else raise UnsupportedClusterProvider
      end
    end
  end

  def server_cluster_paths
    server_cluster_ips.each_with_object({}) do |ip, memo|
      memo[ip] = Setting[:server_master_data].sub_ext("-#{ip}")
    end
  end

  def server_cluster_ips
    if Setting[:server_cluster_ips].present?
      Array.wrap(Setting[:server_cluster_ips])
    else
      server_cluster_list.values
    end
  end

  # TODO run_locally --> so Openstack credentials don't need to be shared
  def server_cluster_list
    @server_cluster_list ||= if Setting.rails_env? :development, :test
      {}
    else
      case Setting[:server_cluster_provider]
      when 'vagrant'   then vagrant_servers(Setting[:server_cluster_name])
      when 'openstack' then openstack_servers(Setting[:server_cluster_name], 'ACTIVE')
      else raise UnsupportedClusterProvider
      end
    end
  end
end
