# TODO add to monit
# https://github.com/hornos/illuminati/blob/master/etc/monit.d/dnsmasq

DNSMASQ_SERVICE_DIR='/etc/systemd/system/dnsmasq.service.d'
export INTERFACE=$(sun.default_interface)
export SERVER_NAME=<%= sun.server %>

sun.install 'dnsmasq'

sun.backup_compile '/etc/dnsmasq.conf'
sun.backup_defaults '/etc/resolv.conf'
sun.backup_move '/etc/dhcp/dhclient.conf'

# no sun.compare_defaults since there are some static IPs
sun.backup_defaults '/etc/hosts'
<%= Sh.build_hosts(sun.server) %>

ufw allow domain
ufw reload

mkdir -p $DNSMASQ_SERVICE_DIR
sun.move "$DNSMASQ_SERVICE_DIR/restart.conf"

systemctl restart networking
systemctl enable dnsmasq
systemctl restart dnsmasq
