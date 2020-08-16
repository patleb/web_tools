case "$OS" in
ubuntu)
  sun.install "python-dev"
  sun.install "python-pip"
  sun.install "python3-dev"
  sun.install "python3-pip"
;;
centos)
  __PYTHON__=${__PYTHON__:-3.6}
  PYTHON_VERSION=$(echo $__PYTHON__ | tr -d '.')

  sun.install "python-devel"
  sun.install "python-pip"
  sun.install "python${PYTHON_VERSION}"
  sun.install "python${PYTHON_VERSION}-libs"
  sun.install "python${PYTHON_VERSION}-devel"
  sun.install "python${PYTHON_VERSION}-pip"
;;
esac
