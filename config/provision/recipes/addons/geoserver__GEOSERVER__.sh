__GEOSERVER__=${__GEOSERVER__:-2.15.0}

wget -q "http://sourceforge.net/projects/geoserver/files/GeoServer/$__GEOSERVER__/geoserver-$__GEOSERVER__-bin.zip"
unzip -q "geoserver-$__GEOSERVER__-bin.zip"
mv "geoserver-$__GEOSERVER__" /opt/geoserver

# https://www.shellhacks.com/systemd-service-file-example/
sun.move '/etc/systemd/system/geoserver.service'

# https://www.google.ca/search?q=geoserver+behind+nginx&oq=geoserver+behind+nginx
# proxy through Nginx
if [[ "$__STAGE__" == 'vagrant' ]]; then
  ufw allow 8080/tcp
  ufw reload
fi

# TODO JAI
# https://geoserver.geo-solutions.it/edu/en/install_run/jai_io_install.html
# https://docs.geoserver.org/latest/en/user/production/java.html
# https://github.com/kartoza/docker-geoserver/blob/master/scripts/setup.sh
# TODO disable unused services --> /opt/geoserver/data_dir/*.xml
sun.backup_move '/opt/geoserver/data_dir/logging.xml'
sun.backup_move '/opt/geoserver/webapps/geoserver/WEB-INF/web.xml'

systemctl enable geoserver
systemctl start geoserver

# https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs
# https://www.loggly.com/ultimate-guide/using-journalctl/
# sudo journalctl -u geoserver.service -f
