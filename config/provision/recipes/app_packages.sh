#  case "$OS" in
#  ubuntu)
#    pip3 install matplotlib==3.2.1
#    sun.install "python3-tk"
#    sun.install "python3-numpy"
#    sun.install "python3-netcdf4"
#    sun.install "python3-psycopg2"
#  ;;
#  centos)
#    __PYTHON__=${__PYTHON__:-3.6}
#    PYTHON_VERSION=$(echo $__PYTHON__ | tr -d '.')
#
#    pip${__PYTHON__} install matplotlib==3.2.1
#    sun.install "python${PYTHON_VERSION}-tkinter"
#    sun.install "python${PYTHON_VERSION}-numpy"
#    sun.install "python${PYTHON_VERSION}-netcdf4"
#    sun.install "python${PYTHON_VERSION}-psycopg2"
#  ;;
#  esac
