case "$OS" in
ubuntu)
  # TODO upgrade
  sudo -H pip3 install pyproj==2.6.1
;;
centos)
  __PYTHON__=${__PYTHON__:-3.6}
  PYTHON_VERSION=$(echo $__PYTHON__ | tr -d '.')

  pip${__PYTHON__} install pyproj==2.6.1
;;
esac
