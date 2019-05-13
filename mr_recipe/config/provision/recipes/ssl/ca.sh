NGINX_DOMAIN=<%= @sun.nginx_domain %>
KEY="/etc/nginx/ssl/$NGINX_DOMAIN.ca.key"
CRT="/etc/nginx/ssl/$NGINX_DOMAIN.ca.crt"

mkdir -p /etc/nginx/ssl
chmod 700 /etc/nginx/ssl

<% if @sun.ssl_ca_key.present? %>
  echo -e "<%= @sun.ssl_ca_key.escape_newlines %>" > $KEY
  echo -e "<%= @sun.ssl_ca_crt.escape_newlines %>" > $CRT
<% else %>
  openssl req \
    -new \
    -newkey rsa:4096 \
    -days 7300 \
    -nodes \
    -x509 \
    -keyout $NGINX_DOMAIN.ca.key \
    -out $NGINX_DOMAIN.ca.crt \
    -subj "/C=<%= @sun.ssl_country || 'CA' %>"\
"/ST=<%= @sun.ssl_state || 'QC' %>"\
"/L=<%= @sun.ssl_city || 'Quebec' %>"\
"/O=<%= @sun.ssl_org || 'self-signed' %>"\
"/CN=$NGINX_DOMAIN"

  mv $NGINX_DOMAIN.ca.key /etc/nginx/ssl/
  mv $NGINX_DOMAIN.ca.crt /etc/nginx/ssl/

  echo "$KEY should be kept encrypted in your settings.yml"
  <%= Sh.escape_newlines "$KEY" %>
  echo "$CRT should be kept in your settings.yml"
  <%= Sh.escape_newlines "$CRT" %>
<% end %>
