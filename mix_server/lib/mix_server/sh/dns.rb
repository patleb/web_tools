module Sh::Dns
  # TODO make it coherent with cap dns:set_hosts
  def build_hosts(owner_name, server)
    entries = (Setting[:dns_hosts] || []).map{ |name| "$PRIVATE_IP  #{name}" }.join("\\n")
    hosts_defaults = "/home/#{owner_name}/#{Sunzistrano::DEFAULTS_DIR}/#{'~etc~hosts'}"
    <<~SH
      PRIVATE_IP=$(#{Sh.private_ip})
      cp #{hosts_defaults} /etc/hosts
      #{append_host 'sh:dns-build_hosts-hostname', '127.0.0.1', '$(hostname)'}
      echo "$PRIVATE_IP  #{server}" | tee -a /etc/hosts
      echo -e "#{entries}" | tee -a /etc/hosts
    SH
  end

  def append_host(id, address, name, **options)
    <<~SH
      #{"if [[ #{options[:if]} ]]; then" if options[:if] }
        sed -rzi -- "s/# #{id}-start.*# #{id}-end\\n//g" /etc/hosts
        echo '# #{id}-start' | tee -a /etc/hosts
        echo "#{address}  #{name}" | tee -a /etc/hosts
        echo '# #{id}-end' | tee -a /etc/hosts
      #{"fi" if options[:if] }
    SH
  end
end
