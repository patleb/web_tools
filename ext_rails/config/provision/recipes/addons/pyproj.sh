case "$OS" in
ubuntu)
  pip3 install pyproj
;;
centos)
  __PYTHON__=${__PYTHON__:-3.6}
  PYTHON_VERSION=$(echo $__PYTHON__ | tr -d '.')

  pip${__PYTHON__} install pyproj
;;
esac
