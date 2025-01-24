sudo add-apt-repository ppa:deadsnakes/ppa
sun.update

sun.install "gdal-bin"
sun.install "libgdal-dev"

sun.install "python3.8"
sun.install "python3.8-distutils"
rm -f /usr/lib/python3/dist-packages/distutils-precedence.pth
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.8

sun.install "python3.8-dev"
sun.install "python3.8-tk"
# pyproj==3.0.1 --> Minimum supported PROJ version is 7.2.0
sudo -H pip3.8 install --root-user-action ignore pyproj==2.6.1
sudo -H pip3.8 install --root-user-action ignore rasterio==1.1.8
sudo -H pip3.8 install --root-user-action ignore matplotlib==3.2.1
sudo -H pip3.8 install --root-user-action ignore numpy==1.26.4
yes | sudo -H pip3.8 uninstall --root-user-action ignore setuptools
sudo -H pip3.8 install --root-user-action ignore psycopg2==2.8.6
sudo -H pip3.8 install --root-user-action ignore netcdf4==1.5.8

python3.8 --version | tr '[:upper:]' '[:lower:]'
pip3.8 --version
