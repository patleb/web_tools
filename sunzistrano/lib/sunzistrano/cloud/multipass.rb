module Cloud
  class Multipass < Base
    def server_master
      if Setting[:server_cluster]
        vm_info.dig(vm_name, :ip_was) || raise('no server master')
      else
        virtual_servers(Setting[:server_host]).values.first
      end
    end

    def server_cluster_list
      virtual_servers(Setting[:server_cluster_name])
    end

    private

    def virtual_servers(filter)
      Host.domains[:virtual].select{ |name, _ip| name.include? filter }
    end

    def vm_name(i = nil)
      name = "vm-#{Setting.app.dasherize}"
      return name if i.nil? || i == 0
      "#{name}-#{Setting[:server_cluster_name]}-#{i}"
    end

    def vm_info
      @vm_info ||= YAML.safe_load(Sunzistrano::MULTIPASS_INFO.read).to_hwia
    end
  end
end
