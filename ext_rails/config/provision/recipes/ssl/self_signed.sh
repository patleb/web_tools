KEY="/etc/nginx/ssl/$__SERVER_HOST__.server.key"
CRT="/etc/nginx/ssl/$__SERVER_HOST__.server.crt"

<% if sun.ssl_server_key.present? %>
  echo -e '<%= sun.ssl_server_key.escape_newlines %>' > $KEY
  echo -e '<%= sun.ssl_server_crt.escape_newlines %>' > $CRT
<% else %>
  # New server key and certificate request
  openssl req \
    -new \
    -newkey rsa:4096 \
    -nodes \
    -keyout $__SERVER_HOST__.server.key \
    -out $__SERVER_HOST__.server.csr \
    -subj "/C=${__SSL_COUNTRY:-CA}"\
"/ST=${__SSL_STATE__:-QC}"\
"/L=${__SSL_CITY__:-Quebec}"\
"/O=${__SSL_ORG__:-self-signed}"\
"/CN=*.$__SERVER_HOST__"

  # New server certificate
  openssl x509 \
    -req \
    -days 7299 \
    -in $__SERVER_HOST__.server.csr \
    -CA /etc/nginx/ssl/$__SERVER_HOST__.ca.crt \
    -CAkey /etc/nginx/ssl/$__SERVER_HOST__.ca.key \
    -set_serial 01 \
    -out $__SERVER_HOST__.server.crt
  rm -f $__SERVER_HOST__.server.csr

  # Move keys to nginx folder
  mv $__SERVER_HOST__.server.key /etc/nginx/ssl/
  mv $__SERVER_HOST__.server.crt /etc/nginx/ssl/

  echo "$KEY should be kept encrypted in your settings.yml as :ssl_server_key"
  <%= Sh.escape_newlines "$KEY" %>
  echo ''
  echo "$CRT should be kept in your settings.yml as :ssl_server_crt"
  <%= Sh.escape_newlines "$CRT" %>
  echo ''
<% end %>
