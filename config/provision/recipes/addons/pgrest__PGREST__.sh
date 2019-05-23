PGREST_VERSION=<%= @sun.pgrest || '5.2.0' %>

case "$OS" in
ubuntu)
  PACKAGE_NAME="postgrest-v$PGREST_VERSION-ubuntu"
;;
centos)
  PACKAGE_NAME="postgrest-v$PGREST_VERSION-centos7"
;;
esac

wget -q "https://github.com/PostgREST/postgrest/releases/download/v$PGREST_VERSION/$PACKAGE_NAME.tar.xz"
tar Jxf "$PACKAGE_NAME.tar.xz"
mkdir -p /opt/pgrest/bin
mv postgrest /opt/pgrest/bin

sun.move '/etc/systemd/system/pgrest.service'

<% if @sun.env.vagrant? %>
  ufw allow 4000/tcp
  ufw reload
<% end %>

systemctl enable pgrest
systemctl start pgrest
