# geoserver doesn't reboot after losing connection on 'sun specialize'
# TODO set '/etc/systemd/system/geoserver.service' Xmx2048M with __GEOSERVER_MAX_SIZE__
systemctl start geoserver || :
