PGIS_PACKAGES="postgresql-${postgres}-postgis-${postgis} postgresql-${postgres}-postgis-${postgis}-scripts"

sun.update
sun.install "gdal-bin"
sun.install "libgdal-dev"
sun.install "$PGIS_PACKAGES"
sun.lock "$PGIS_PACKAGES"
