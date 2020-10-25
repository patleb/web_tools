KEY="/etc/nginx/ssl/$__SERVER_HOST__.ca.key"
CRT="/etc/nginx/ssl/$__SERVER_HOST__.ca.crt"

mkdir -p /etc/nginx/ssl
chmod 700 /etc/nginx/ssl

<% if sun.ssl_ca_key.present? %>
  echo -e "<%= sun.ssl_ca_key.escape_newlines %>" > $KEY
  echo -e "<%= sun.ssl_ca_crt.escape_newlines %>" > $CRT
<% else %>
  openssl rand -writerand /home/$__OWNER_NAME__/.rnd
  openssl req \
    -new \
    -newkey rsa:4096 \
    -days 7300 \
    -nodes \
    -x509 \
    -keyout $__SERVER_HOST__.ca.key \
    -out $__SERVER_HOST__.ca.crt \
    -subj "/C=${__SSL_COUNTRY__:-CA}"\
"/ST=${__SSL_STATE__:-QC}"\
"/L=${__SSL_CITY__:-Quebec}"\
"/O=${__SSL_ORG__:-self-signed}"\
"/CN=$__SERVER_HOST__"

  mv $__SERVER_HOST__.ca.key /etc/nginx/ssl/
  mv $__SERVER_HOST__.ca.crt /etc/nginx/ssl/

  echo "$KEY should be kept encrypted in your settings.yml as :ssl_ca_key"
  <%= Sh.escape_newlines "$KEY" %>
  echo ''
  echo "$CRT should be kept in your settings.yml as :ssl_ca_crt"
  <%= Sh.escape_newlines "$CRT" %>
  echo ''
<% end %>
