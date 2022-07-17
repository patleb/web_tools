KEY="/etc/nginx/ssl/${server_host}.ca.key"
CRT="/etc/nginx/ssl/${server_host}.ca.crt"

mkdir -p /etc/nginx/ssl
chmod 700 /etc/nginx/ssl

<% if sun.ssl_ca_key.present? %>
  echo -e "<%= sun.ssl_ca_key.escape_newlines %>" > $KEY
  echo -e "<%= sun.ssl_ca_crt.escape_newlines %>" > $CRT
<% else %>
  openssl rand -writerand /home/${owner_name}/.rnd
  openssl req \
    -new \
    -newkey rsa:4096 \
    -days 7300 \
    -nodes \
    -x509 \
    -keyout ${server_host}.ca.key \
    -out ${server_host}.ca.crt \
    -subj "/C=${__SSL_COUNTRY__:-CA}"\
"/ST=${__SSL_STATE__:-QC}"\
"/L=${__SSL_CITY__:-Quebec}"\
"/O=${__SSL_ORG__:-self-signed}"\
"/CN=${server_host}"

  mv ${server_host}.ca.key /etc/nginx/ssl/
  mv ${server_host}.ca.crt /etc/nginx/ssl/

  echo "$KEY should be kept encrypted in your settings.yml as :ssl_ca_key"
  <%= Sh.escape_newlines "$KEY" %>
  echo ''
  echo "$CRT should be kept in your settings.yml as :ssl_ca_crt"
  <%= Sh.escape_newlines "$CRT" %>
  echo ''
<% end %>
