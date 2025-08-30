module Cloud
  class Base
    def self.build(provider)
      if Setting.local? :computer
        Localhost.new
      else
        Cloud.const_get(provider.to_s.camelize).new
      end
    end

    def server_master
      raise NotImplementedError
    end

    def server_cluster_list
      raise NotImplementedError
    end

    def server_cluster_ips
      server_cluster_list.values
    end

    def server_cluster_paths
      server_cluster_ips.each_with_object({}) do |ip, memo|
        memo[ip] = Setting[:server_master_data].sub_ext("-#{ip}")
      end
    end
  end
end
