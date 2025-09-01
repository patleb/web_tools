module Cloud
  class Custom < Base
    def master_ip
      Setting[:cloud_master_ip]
    end

    def cluster_ips
      Array.wrap(Setting[:cloud_cluster_ips])
    end
  end
end
