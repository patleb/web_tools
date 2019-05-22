GEOSERVER_VERSION=<%= @sun.geoserver || '2.15.1' %>

wget -q "https://netcologne.dl.sourceforge.net/project/geoserver/GeoServer/$GEOSERVER_VERSION/geoserver-$GEOSERVER_VERSION-bin.zip"
unzip -q "geoserver-$GEOSERVER_VERSION-bin.zip"
mv "geoserver-$GEOSERVER_VERSION" /opt/geoserver

echo 'export GEOSERVER_HOME=/opt/geoserver' >> $HOME/.bashrc
