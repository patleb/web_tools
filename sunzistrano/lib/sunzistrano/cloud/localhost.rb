module Cloud
  class Localhost < Base
    def server_master
      '127.0.0.1'
    end

    def server_cluster_list
      {}
    end
  end
end
