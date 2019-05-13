NGINX_DOMAIN=<%= @sun.nginx_domain %>
KEY="/etc/nginx/ssl/$NGINX_DOMAIN.server.key"
CRT="/etc/nginx/ssl/$NGINX_DOMAIN.server.crt"

<% if @sun.ssl_server_key.present? %>
  echo -e '<%= @sun.ssl_server_key.escape_newlines %>' > $KEY
  echo -e '<%= @sun.ssl_server_crt.escape_newlines %>' > $CRT
<% else %>
  # New server key and certificate request
  openssl req \
    -new \
    -newkey rsa:4096 \
    -nodes \
    -keyout $NGINX_DOMAIN.server.key \
    -out $NGINX_DOMAIN.server.csr \
    -subj "/C=<%= @sun.ssl_country || 'CA' %>"\
"/ST=<%= @sun.ssl_state || 'QC' %>"\
"/L=<%= @sun.ssl_city || 'Quebec' %>"\
"/O=<%= @sun.ssl_org || 'self-signed' %>"\
"/CN=*.$NGINX_DOMAIN"

  # New server certificate
  openssl x509 \
    -req \
    -days 7000 \
    -in $NGINX_DOMAIN.server.csr \
    -CA /etc/nginx/ssl/$NGINX_DOMAIN.ca.crt \
    -CAkey /etc/nginx/ssl/$NGINX_DOMAIN.ca.key \
    -set_serial 01 \
    -out $NGINX_DOMAIN.server.crt
  rm -f $NGINX_DOMAIN.server.csr

  # Move keys to nginx folder
  mv $NGINX_DOMAIN.server.key /etc/nginx/ssl/
  mv $NGINX_DOMAIN.server.crt /etc/nginx/ssl/

  echo "$KEY should be kept encrypted in your settings.yml"
  <%= Sh.escape_newlines "$KEY" %>
  echo "$CRT should be kept in your settings.yml"
  <%= Sh.escape_newlines "$CRT" %>
<% end %>
