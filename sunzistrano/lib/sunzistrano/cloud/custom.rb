module Cloud
  class Custom < Base
    def server_master
      Setting[:server_master_ip]
    end

    def server_cluster_list
      Array.wrap(Setting[:server_cluster_ips]).index_with{ it }
    end
  end
end
