module Sh::Vpn
  def create_client_ovpn(name:, linux: true, print: false)
    raise 'client name must be specified' unless name.present?
    client_ovpn = client_ovpn(name)
    linux = linux.to_b ? '' : ';'
    linux_conf = <<~CONF
    
      # Linux specifics (comment out for Windows)
      #{linux}log-append  /var/log/openvpn.log
      #{linux}script-security 2
      #{linux}up /etc/openvpn/update-resolv-conf
      #{linux}down /etc/openvpn/update-resolv-conf
    CONF
    if print.to_b
      print_key = <<~SH
        echo "'#{client_ovpn}' should be kept encrypted in your settings.yml"
        #{Sh.escape_newlines client_ovpn}
      SH
    end
    <<~SH
      if [[ -f '#{client_ovpn}' ]]; then
        echo "'#{client_ovpn}' already exists"
        exit 1
      fi
      cd '#{ca_dir}' && source '#{ca_dir}/vars'
      ./build-key '#{name}' <<EOF
    
    
    
    
    
    
    
    
    
    
      y
      y
      EOF
      cat '/etc/openvpn/client.conf' \
        <(echo -e '#{linux_conf.escape_newlines}' ) \
        <(echo -e '<ca>')   '#{ca_keys_dir}/ca.crt'      <(echo -e '</ca>') \
        <(echo -e '<cert>') '#{ca_keys_dir}/#{name}.crt' <(echo -e '</cert>') \
        <(echo -e '<key>')  '#{ca_keys_dir}/#{name}.key' <(echo -e '</key>') \
        <(echo -e '<tls-auth>') '#{ca_keys_dir}/ta.key'  <(echo -e '</tls-auth>') \
        > '#{client_ovpn}'
      #{print_key}
    SH
  end

  def revoke_client_ovpn(name:)
    raise 'client name must be specified' unless name.present?
    client_ovpn = client_ovpn(name)
    <<~SH
      if [[ ! -f '#{client_ovpn}' ]]; then
        echo "'#{client_ovpn}' doesn't exist"
        exit 1
      fi
      cd '#{ca_dir}' && source '#{ca_dir}/vars'
      ./revoke-full '#{name}'
      cp -f '#{ca_keys_dir}/crl.pem' /etc/openvpn
      #{Sh.concat '/etc/openvpn/server.conf', 'crl-verify crl.pem', unique: true}
    SH
  end

  private

  def ca_dir
    '/opt/openvpn_data/ca'
  end

  def ca_keys_dir
    "#{ca_dir}/keys"
  end

  def clients_dir
    '/opt/openvpn_data/clients'
  end

  def client_ovpn(name)
    "#{clients_dir}/keys/#{name}.ovpn"
  end
end
