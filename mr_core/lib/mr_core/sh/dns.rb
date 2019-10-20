module Sh::Dns
  def build_hosts(admin_name, server)
    entries = (Setting[:dns_hosts] || []).map{ |name| "$INTERNAL_IP  #{name}" }.join("\\n")
    hosts_defaults = "/home/#{admin_name}/#{Sunzistrano::Config::DEFAULTS_DIR}/#{'~etc~hosts'}"
    <<~SH
      INTERNAL_IP=$(#{Sh.internal_ip})
      cp #{hosts_defaults} /etc/hosts
      #{append_host 'sh:dns-build_hosts-hostname', '127.0.0.1', '$(hostname)'}
      echo "$INTERNAL_IP  #{server}" | tee -a /etc/hosts
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
