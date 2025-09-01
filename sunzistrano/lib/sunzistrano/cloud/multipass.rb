module Cloud
  class Multipass < Base
    def master_ip
      if Setting[:cloud_cluster]
        YAML.safe_load(Sunzistrano::MULTIPASS_INFO.read).dig("vm-#{Setting.default_app.dasherize}", 'ip_was')
      else
        Host.domains.dig(:virtual, Setting[:server_host])
      end
    end

    def cluster_ips
      if Host.domains[:virtual].nil?
        Pathname.new(Dir.home).join("#{Setting.env}_#{Setting[:cloud_cluster_name]}").read.strip.split(',')
      else
        Host.domains[:virtual].select_map{ |name, ip| name.include?(Setting[:cloud_cluster_name]) && ip }
      end
    end
  end
end
