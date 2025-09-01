module Cloud
  class Localhost < Base
    def master_ip
      '127.0.0.1'
    end

    def cluster_ips
      []
    end
  end
end
