case "$OS" in
ubuntu)
  sun.install "gdal-bin"
  sun.install "libgdal-dev"
;;
centos)
  sun.install "gdal"
  sun.install "gdal-devel"
;;
esac
