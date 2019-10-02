module SunCap
  class UnsupportedClusterProvider < ::StandardError; end

  def self.server_cluster
    case Setting[:server_cluster_provider]
    when 'vagrant'
      list = `vagrant global-status | grep virtualbox | awk '{ print $2; }'`.lines.map(&:strip)
      list.select!(&:include?.with(Setting[:server_cluster_name]))
      list.map!{ |name| `vagrant ssh #{name} -c "hostname -I | cut -d' ' -f2" 2>/dev/null`.strip }
    when 'openstack'
      os_vars = Setting.select{ |k, _| k.start_with? 'os_' }.map{ |k, v| "#{k.upcase}='#{v}'" }.join(' ')
      list = `#{os_vars} openstack --quiet server list | grep '#{Setting[:os_project_name]}' | grep '#{Setting[:server_cluster_name]}' | cut -d'|' -f5 | cut -d'=' -f2`
      list.lines.map(&:strip)
    else
      raise UnsupportedClusterProvider
    end
  end
end
