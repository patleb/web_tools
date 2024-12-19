sun.install "gdal-bin"
sun.install "libgdal-dev"
# pyproj==3.0.1 --> Minimum supported PROJ version is 7.2.0, installed version is 4.9.3
sudo -H pip3 install pyproj==2.6.1
sudo -H pip3 install rasterio==1.1.8
sudo -H pip3 install matplotlib==3.2.1
sun.install "python3-tk"
sun.install "python3-numpy"
sun.install "python3-psycopg2"
