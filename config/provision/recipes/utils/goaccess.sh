case "$OS" in
ubuntu)
  echo "deb http://deb.goaccess.io/ $UBUNTU_CODENAME main" | tee -a /etc/apt/sources.list.d/goaccess.list
  wget -O - http://deb.goaccess.io/gnugpg.key | apt-key add -
  sun.update

  sun.install "libgeoip-dev"
  sun.install "libtokyocabinet-dev"
  sun.install "goaccess"
;;
centos)
  sun.install "geoip-devel"
  sun.install "tokyocabinet-devel"
  sun.install "goaccess"
;;
esac

sun.backup_compile '/etc/goaccess.conf'
