DEPLOYER_NAME=<%= @sun.deployer_name %>
GEOSERVER_VERSION=<%= @sun.geoserver || '2.15.1' %>

wget -q "http://sourceforge.net/projects/geoserver/files/GeoServer/$GEOSERVER_VERSION/geoserver-$GEOSERVER_VERSION-bin.zip"
unzip -q "geoserver-$GEOSERVER_VERSION-bin.zip"
mv "geoserver-$GEOSERVER_VERSION" /opt/geoserver

sun.move '/etc/systemd/system/geoserver.service'

# https://www.google.ca/search?q=geoserver+behind+nginx&oq=geoserver+behind+nginx
# proxy through Nginx
<% if @sun.env.vagrant? %>
  ufw allow 8080/tcp
  ufw reload
<% end %>

systemctl enable geoserver
systemctl start geoserver

# sudo journalctl -u geoserver.service -f
