module Cloud
  class Base
    def self.build(provider)
      if Setting.local? :computer
        Localhost.new
      else
        Cloud.const_get(provider.to_s.camelize).new
      end
    end

    def master_ip
      raise NotImplementedError
    end

    def cluster_ips
      raise NotImplementedError
    end

    def cluster_paths
      cluster_ips.each_with_object({}) do |ip, memo|
        memo[ip] = Setting[:cloud_master_data].sub_ext("-#{ip}")
      end
    end
  end
end
