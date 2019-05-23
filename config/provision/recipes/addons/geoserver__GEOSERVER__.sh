DEPLOYER_NAME=<%= @sun.deployer_name %>
GEOSERVER_VERSION=<%= @sun.geoserver || '2.15.1' %>

wget -q "https://netcologne.dl.sourceforge.net/project/geoserver/GeoServer/$GEOSERVER_VERSION/geoserver-$GEOSERVER_VERSION-bin.zip"
unzip -q "geoserver-$GEOSERVER_VERSION-bin.zip"
mv "geoserver-$GEOSERVER_VERSION" /opt/geoserver

echo 'export GEOSERVER_HOME=/opt/geoserver' >> /home/$DEPLOYER_NAME/.bashrc
chown -R $DEPLOYER_NAME:$DEPLOYER_NAME /opt/geoserver

# https://www.google.ca/search?q=geoserver+behind+nginx&oq=geoserver+behind+nginx
# proxy through Nginx
# ufw allow 8080/tcp
# ufw reload
