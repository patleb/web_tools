geoserver=${geoserver:-2.21.0}
export geoserver_max_size=${geoserver_max_size:-2048M}

if [[ -d /opt/geoserver ]]; then
  systemctl stop geoserver
  systemctl disable geoserver
  rm -rf /opt/geoserver
  rm -f /etc/systemd/system/geoserver.service
  sun.remove_defaults '/opt/geoserver/start.ini'
  sun.remove_defaults '/opt/geoserver/data_dir/logging.xml'
  sun.remove_defaults '/opt/geoserver/webapps/geoserver/WEB-INF/web.xml'
fi

wget -q "http://sourceforge.net/projects/geoserver/files/GeoServer/${geoserver}/geoserver-${geoserver}-bin.zip"
unzip -q "geoserver-${geoserver}-bin.zip"
mv "geoserver-${geoserver}" /opt/geoserver

# https://www.shellhacks.com/systemd-service-file-example/
sun.compile '/etc/systemd/system/geoserver.service'

# https://www.google.ca/search?q=geoserver+behind+nginx&oq=geoserver+behind+nginx
# proxy through Nginx
if [[ "${env}" == 'vagrant' ]]; then
  ufw allow 8080/tcp
  ufw reload
fi

# TODO JAI
# https://geoserver.geo-solutions.it/edu/en/install_run/jai_io_install.html
# https://docs.geoserver.org/latest/en/user/production/java.html
# https://github.com/kartoza/docker-geoserver/blob/master/scripts/setup.sh
# TODO disable unused services --> /opt/geoserver/data_dir/*.xml
sun.backup_copy '/opt/geoserver/start.ini' 0644 root:root
sun.backup_copy '/opt/geoserver/data_dir/logging.xml' 0644 root:root
sun.backup_copy '/opt/geoserver/webapps/geoserver/WEB-INF/web.xml' 0644 root:root

systemctl enable geoserver
systemctl start geoserver

# https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs
# https://www.loggly.com/ultimate-guide/using-journalctl/
# sudo journalctl -u geoserver.service -f
