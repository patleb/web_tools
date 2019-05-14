sun.install 'openvpn'

<% if @sun.vpn_client_ovpn %>
  echo -e "<%= @sun.vpn_client_ovpn.escape_newlines %>" > /etc/openvpn/<%= @sun.vpn_client_name || "client_#{@sun.stage}" %>.conf
<% else %>
  echo 'client.ovpn not available'
  exit 1
<% end %>

<%= Sh.sub! '/etc/default/openvpn', '#AUTOSTART="none"', 'AUTOSTART="none"' %>

systemctl daemon-reload
systemctl stop openvpn@<%= @sun.vpn_client_name || "client_#{@sun.stage}" %>
systemctl restart openvpn
