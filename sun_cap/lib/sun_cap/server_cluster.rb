module SunCap
  class UnsupportedClusterProvider < ::StandardError; end

  def self.server_cluster_master
    if Setting[:server_cluster_master_ip].present?
      Setting[:server_cluster_master_ip]
    else
      case Setting[:server_cluster_provider]
      when 'vagrant'   then vagrant_server_list(Setting[:server_host]).first
      when 'openstack' then openstack_server_list(Setting[:server_cluster_master]).first
      else raise UnsupportedClusterProvider
      end
    end
  end

  def self.server_cluster
    if Setting[:server_cluster_ips].present?
      Setting[:server_cluster_ips]
    else
      case Setting[:server_cluster_provider]
      when 'vagrant'   then vagrant_server_list(Setting[:server_cluster_name])
      when 'openstack' then openstack_server_list(Setting[:server_cluster_name])
      else raise UnsupportedClusterProvider
      end
    end
  end

  private_class_method

  def self.vagrant_server_list(filter)
    list = Pathname.new('/etc/hosts').readlines
    list.select!{ |line| true if (line =~ /vagrant-hostmanager-start/ .. line =~ /vagrant-hostmanager-end/) }
    list[1..-2].select(&:include?.with(filter)).map(&:split).map(&:first)
  end

  def self.openstack_server_list(*filters, state: 'ACTIVE')
    os_vars = Setting.select{ |k, _| k.start_with? 'os_' }.map{ |k, v| "#{k.upcase}='#{v}'" }.join(' ')
    grep = [*filters, state].map{ |filter| "grep '#{filter}'" }
    list = `#{os_vars} openstack -q server list | #{grep.join(' | ')} | cut -d'|' -f5 | cut -d'=' -f2`
    list.lines.map(&:strip)
  end
end
