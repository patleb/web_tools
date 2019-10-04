module SunCap
  class UnsupportedClusterProvider < ::StandardError; end

  def self.server_cluster
    return Setting[:server_cluster] if Setting[:server_cluster].present?

    case Setting[:server_cluster_provider]
    when 'vagrant'
      list = Pathname.new('/etc/hosts').readlines
      list.select!{ |line| true if (line =~ /vagrant-hostmanager-start/ .. line =~ /vagrant-hostmanager-end/) }
      list[1..-2].select(&:include?.with(Setting[:server_cluster_name])).map(&:split).map(&:first)
    when 'openstack'
      os_vars = Setting.select{ |k, _| k.start_with? 'os_' }.map{ |k, v| "#{k.upcase}='#{v}'" }.join(' ')
      grep = [Setting[:server_cluster_name], 'ACTIVE'].map{ |filter| "grep '#{filter}'" }
      list = `#{os_vars} openstack -q server list | #{grep.join(' | ')} | cut -d'|' -f5 | cut -d'=' -f2`
      list.lines.map(&:strip)
    else
      raise UnsupportedClusterProvider
    end
  end
end
