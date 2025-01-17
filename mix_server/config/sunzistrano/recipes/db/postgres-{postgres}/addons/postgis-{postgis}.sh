PG_CONFIG_FILE=$(pg.config_file)
PGIS_PACKAGES="postgresql-${postgres}-postgis-${postgis} postgresql-${postgres}-postgis-${postgis}-scripts"
postgis_gdal_enabled_drivers=${postgis_gdal_enabled_drivers:-ENABLE_ALL}

sun.update
sun.install "gdal-bin"
sun.install "libgdal-dev"
sun.install "$PGIS_PACKAGES"
sun.lock "$PGIS_PACKAGES"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'postgis.gdal_enabled_drivers =' %>
echo "postgis.gdal_enabled_drivers = '${postgis_gdal_enabled_drivers}'" >> "$PG_CONFIG_FILE"

pg.restart_force
