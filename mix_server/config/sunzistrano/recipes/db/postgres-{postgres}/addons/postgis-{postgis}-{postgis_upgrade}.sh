postgis_upgrade=${postgis_upgrade:-false}

if [[ "${postgis_upgrade}" != false ]]; then
  PGIS_PACKAGES="postgresql-${postgres}-postgis-${postgis} postgresql-${postgres}-postgis-${postgis}-scripts"

  sun.unlock "$PGIS_PACKAGES"
  sun.update
  for package in ${PGIS_PACKAGES}; do
    sudo apt-get install -y "$package"
  done
  sun.lock "$PGIS_PACKAGES"

  pg.restart_force
fi
