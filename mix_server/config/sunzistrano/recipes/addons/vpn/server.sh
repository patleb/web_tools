export VPN_DOMAIN=<%= sun.vpn_domain %>
export INTERFACE=$(sun.default_interface)
export PRIVATE_IP=$(sun.private_ip)
export LOCAL_NETWORK="$(sun.network $PRIVATE_IP 24) $(sun.netmask 24)"
OPENVPN_DIR='/etc/openvpn'
SERVER_CONF="$OPENVPN_DIR/server.conf"
CLIENT_CONF="$OPENVPN_DIR/client.conf"
CA_DIR="/opt/openvpn_data/ca"
CA_VARS="$CA_DIR/vars"
CA_KEYS_DIR="$CA_DIR/keys"
CLIENTS_DIR="/opt/openvpn_data/clients"
CLIENTS_KEYS="$CLIENTS_DIR/keys"

sun.backup_compile '/etc/ufw/before.rules' 0640
sun.backup_compile '/etc/ufw/sysctl.conf'

sun.copy '/etc/fail2ban/filter.d/openvpn.conf'
sun.copy '/etc/fail2ban/jail.d/openvpn.conf'

sun.install 'openvpn'
sun.install 'easy-rsa'

cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz $OPENVPN_DIR/ && gzip -d $SERVER_CONF.gz
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf $CLIENT_CONF
sun.backup_compile $SERVER_CONF
sun.backup_compile $CLIENT_CONF

make-cadir $CA_DIR
sun.backup_copy $CA_VARS

mkdir -p $CLIENTS_KEYS
chmod 700 $CLIENTS_KEYS

cd $CA_DIR && source $CA_VARS
./clean-all

<% unless sun.vpn_client_ovpn %>
  yes '' | ./build-ca
  ./build-key-server server <<EOF










y
y
EOF
  ./build-dh
  openvpn --genkey --secret $CA_KEYS_DIR/ta.key

  cd $CA_KEYS_DIR
  cp ca.crt ca.key server.crt server.key ta.key dh2048.pem $OPENVPN_DIR

  <%= Sh.create_client_ovpn(name: sun.vpn_client_name || "client_#{sun.env}", linux: true, print: true) %>
<% end %>

ufw allow openvpn
ufw reload

systemctl enable openvpn@server
<% if sun.vpn_client_ovpn %>
  touch /var/log/openvpn.log
<% else %>
  systemctl start openvpn@server
<% end %>

systemctl restart fail2ban
