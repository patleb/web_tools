case "$OS" in
ubuntu)
  echo "deb [arch=$ARCH] http://deb.goaccess.io/ $UBUNTU_CODENAME main" | tee -a /etc/apt/sources.list.d/goaccess.list
  wget -O - http://deb.goaccess.io/gnugpg.key | apt-key add -
  sun.update

  sun.install "libgeoip-dev"
  sun.install "libtokyocabinet-dev"
  sun.install "goaccess"
  # TODO https://flamy.ca/blog/2020-03-13-goaccess-as-google-analytics-replacement.html
  # sun.install "geoip-database"

  sun.backup_move '/etc/goaccess/goaccess.conf'
;;
centos)
  sun.install "geoip-devel"
  sun.install "tokyocabinet-devel"
  sun.install "goaccess"

  sun.backup_move '/etc/goaccess.conf'
;;
esac
