KEY="/etc/nginx/ssl/${server_host}.server.key"
CRT="/etc/nginx/ssl/${server_host}.server.crt"

<% if sun.ssl_server_key.present? %>
  echo -e '<%= sun.ssl_server_key.escape_newlines %>' > $KEY
  echo -e '<%= sun.ssl_server_crt.escape_newlines %>' > $CRT
<% else %>
  # New server key and certificate request
  openssl req \
    -new \
    -newkey rsa:4096 \
    -nodes \
    -keyout ${server_host}.server.key \
    -out ${server_host}.server.csr \
    -subj "/C=${ssl_country:-CA}"\
"/ST=${ssl_state:-QC}"\
"/L=${ssl_city:-Quebec}"\
"/O=${ssl_org:-self-signed}"\
"/CN=*.${server_host}"

  # New server certificate
  openssl x509 \
    -req \
    -days 7299 \
    -in ${server_host}.server.csr \
    -CA /etc/nginx/ssl/${server_host}.ca.crt \
    -CAkey /etc/nginx/ssl/${server_host}.ca.key \
    -set_serial 01 \
    -out ${server_host}.server.crt
  rm -f ${server_host}.server.csr

  # Move keys to nginx folder
  mv ${server_host}.server.key /etc/nginx/ssl/
  mv ${server_host}.server.crt /etc/nginx/ssl/

  echo "$KEY should be kept encrypted in your settings.yml as :ssl_server_key"
  <%= Sh.escape_newlines "$KEY" %>
  echo ''
  echo "$CRT should be kept in your settings.yml as :ssl_server_crt"
  <%= Sh.escape_newlines "$CRT" %>
  echo ''
<% end %>
