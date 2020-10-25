KEY="/etc/nginx/ssl/$__NGINX_DOMAIN__.server.key"
CRT="/etc/nginx/ssl/$__NGINX_DOMAIN__.server.crt"

<% if sun.ssl_server_key.present? %>
  echo -e '<%= sun.ssl_server_key.escape_newlines %>' > $KEY
  echo -e '<%= sun.ssl_server_crt.escape_newlines %>' > $CRT
<% else %>
  # New server key and certificate request
  openssl req \
    -new \
    -newkey rsa:4096 \
    -nodes \
    -keyout $__NGINX_DOMAIN__.server.key \
    -out $__NGINX_DOMAIN__.server.csr \
    -subj "/C=${__SSL_COUNTRY:-CA}"\
"/ST=${__SSL_STATE__:-QC}"\
"/L=${__SSL_CITY__:-Quebec}"\
"/O=${__SSL_ORG__:-self-signed}"\
"/CN=*.$__NGINX_DOMAIN__"

  # New server certificate
  openssl x509 \
    -req \
    -days 7299 \
    -in $__NGINX_DOMAIN__.server.csr \
    -CA /etc/nginx/ssl/$__NGINX_DOMAIN__.ca.crt \
    -CAkey /etc/nginx/ssl/$__NGINX_DOMAIN__.ca.key \
    -set_serial 01 \
    -out $__NGINX_DOMAIN__.server.crt
  rm -f $__NGINX_DOMAIN__.server.csr

  # Move keys to nginx folder
  mv $__NGINX_DOMAIN__.server.key /etc/nginx/ssl/
  mv $__NGINX_DOMAIN__.server.crt /etc/nginx/ssl/

  echo "$KEY should be kept encrypted in your settings.yml"
  <%= Sh.escape_newlines "$KEY" %>
  echo "$CRT should be kept in your settings.yml"
  <%= Sh.escape_newlines "$CRT" %>
<% end %>
