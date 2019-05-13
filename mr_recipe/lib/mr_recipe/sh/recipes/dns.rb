module Sh::Dns
  def build_hosts(admin_name, server)
    entries = (Secret[:dns_hosts] || []).map{ |name| "$INTERNAL_IP  #{name}" }.join("\\n")

    hosts = '/etc/hosts'
    hosts_defaults = "/home/#{admin_name}/#{Sunzistrano::Config::DEFAULTS_DIR}/#{hosts.tr('/', '~')}"
    <<~BASH
      INTERNAL_IP=$(#{Sh.internal_ip})
      cp '#{hosts_defaults}' '#{hosts}'
      if ! grep -q $(hostname) '#{hosts}'; then
        echo "127.0.0.1  $(hostname)" | tee -a '#{hosts}'
      fi
      echo "$INTERNAL_IP  #{server}" | tee -a '#{hosts}'
      echo -e "#{entries}" | tee -a '#{hosts}'
    BASH
  end
end
