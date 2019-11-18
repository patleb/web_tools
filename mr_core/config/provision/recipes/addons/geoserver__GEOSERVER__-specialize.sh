export __GEOSERVER_MAX_SIZE__=${__GEOSERVER_MAX_SIZE__:-2048M}

sun.compile '/etc/systemd/system/geoserver.service'

# geoserver doesn't reboot after losing connection on 'sun specialize'
systemctl start geoserver || systemctl restart geoserver
