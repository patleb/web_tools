export geoserver_max_size=${geoserver_max_size:-2048M}

sun.compile '/etc/systemd/system/geoserver.service'
systemctl daemon-reload

# geoserver doesn't reboot after losing connection on 'sun specialize'
systemctl restart geoserver || systemctl start geoserver || :
