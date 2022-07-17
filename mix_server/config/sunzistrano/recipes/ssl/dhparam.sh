DH="/etc/nginx/ssl/${server_host}.server.dh"

<% if sun.ssl_server_dh.present? %>
  echo -e '<%= sun.ssl_server_dh.escape_newlines %>' > $DH
<% else %>
  openssl dhparam -out $DH 4096

  echo "$DH should be kept in your settings.yml as :ssl_server_dh"
  <%= Sh.escape_newlines "$DH" %>
  echo ''
<% end %>
