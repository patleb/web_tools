echo "deb http://deb.goaccess.io/ $UBUNTU_CODENAME main" | tee -a /etc/apt/sources.list.d/goaccess.list
wget -O - http://deb.goaccess.io/gnugpg.key | apt-key add -
sun.update

sun.install "goaccess"

sun.backup_compile '/etc/goaccess.conf'
