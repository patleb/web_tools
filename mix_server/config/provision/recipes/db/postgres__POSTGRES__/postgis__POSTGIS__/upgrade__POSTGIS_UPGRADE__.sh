__POSTGIS_UPGRADE__=${__POSTGIS_UPGRADE__:-false}

if [[ "$__POSTGIS_UPGRADE__" != false ]]; then
  PGIS_PACKAGES="postgresql-$__POSTGRES__-postgis-$__POSTGIS__ postgresql-$__POSTGRES__-postgis-$__POSTGIS__-scripts"

  sun.unlock "$PGIS_PACKAGES"
  sun.update
  for package in ${PGIS_PACKAGES}; do
    sudo apt-get install -y "$package"
  done
  sun.lock "$PGIS_PACKAGES"

  sun.pg_restart_force
fi
