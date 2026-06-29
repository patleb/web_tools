NETWORK_NAME=$(nmcli connection show | grep $(sun.default_interface) | awk '{print $1}')
STATIC_IP=$(sun.private_ip)
nmcli connection modify "$NETWORK_NAME" \
  ipv4.method manual \
  ipv4.addresses "$STATIC_IP/24" \
  ipv4.gateway "${STATIC_IP%.*}.1" \
  ipv4.dns "1.1.1.1 8.8.8.8"
nmcli connection down "$NETWORK_NAME"
nmcli connection up "$NETWORK_NAME"
