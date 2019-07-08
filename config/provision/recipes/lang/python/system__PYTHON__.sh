PYTHON_VERSION=<%= @sun.python || '3.6' %>

case "$OS" in
ubuntu)
  sun.install "python-dev"
  sun.install "python-pip"
  sun.install "python3-dev"
  sun.install "python3-pip"
;;
centos)
  PYTHON_VERSION=$(echo $PYTHON_VERSION | tr -d '.')
  sun.install "python${PYTHON_VERSION}"
  sun.install "python${PYTHON_VERSION}-libs"
  sun.install "python${PYTHON_VERSION}-devel"
  sun.install "python${PYTHON_VERSION}-pip"
;;
esac
