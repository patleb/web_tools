module SunCap
  class UnsupportedClusterProvider < ::StandardError; end

  def self.server_cluster
    case Setting[:server_cluster_provider]
    when 'vagrant'
      list = `vagrant global-status | grep virtualbox | tr -s [:blank:] | cut -d' ' -f2`.lines.map(&:strip)
      list.select!(&:include?.with(Setting[:server_cluster_name]))
      list.map!{ |name| `vagrant ssh #{name} -c "hostname -I | cut -d' ' -f2" 2>/dev/null`.strip }
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
