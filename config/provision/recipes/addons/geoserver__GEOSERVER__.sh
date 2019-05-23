GEOSERVER_VERSION=<%= @sun.geoserver || '2.15.0' %>

wget -q "http://sourceforge.net/projects/geoserver/files/GeoServer/$GEOSERVER_VERSION/geoserver-$GEOSERVER_VERSION-bin.zip"
unzip -q "geoserver-$GEOSERVER_VERSION-bin.zip"
mv "geoserver-$GEOSERVER_VERSION" /opt/geoserver

# https://www.shellhacks.com/systemd-service-file-example/
sun.move '/etc/systemd/system/geoserver.service'

# https://www.google.ca/search?q=geoserver+behind+nginx&oq=geoserver+behind+nginx
# proxy through Nginx
<% if @sun.env.vagrant? %>
  ufw allow 8080/tcp
  ufw reload
<% end %>

systemctl enable geoserver
systemctl start geoserver

# https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs
# https://www.loggly.com/ultimate-guide/using-journalctl/
# sudo journalctl -u geoserver.service -f
