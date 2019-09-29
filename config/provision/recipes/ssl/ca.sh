KEY="/etc/nginx/ssl/$__NGINX_DOMAIN__.ca.key"
CRT="/etc/nginx/ssl/$__NGINX_DOMAIN__.ca.crt"

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
    -keyout $__NGINX_DOMAIN__.ca.key \
    -out $__NGINX_DOMAIN__.ca.crt \
    -subj "/C=${__SSL_COUNTRY__:-CA}"\
"/ST=${__SSL_STATE__:-QC}"\
"/L=${__SSL_CITY__:-Quebec}"\
"/O=${__SSL_ORG__:-self-signed}"\
"/CN=$__NGINX_DOMAIN__"

  mv $__NGINX_DOMAIN__.ca.key /etc/nginx/ssl/
  mv $__NGINX_DOMAIN__.ca.crt /etc/nginx/ssl/

  echo "$KEY should be kept encrypted in your settings.yml"
  <%= Sh.escape_newlines "$KEY" %>
  echo "$CRT should be kept in your settings.yml"
  <%= Sh.escape_newlines "$CRT" %>
<% end %>
