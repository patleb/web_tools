postgres_upgrade=${postgres_upgrade:-false}

if [[ "${postgres_upgrade}" != false ]]; then
  PG_PACKAGES="postgresql-${postgres} postgresql-server-dev-${postgres} postgresql-common libpq-dev"

  sun.update

  PG_VERSION="$(sun.available_version postgresql-${postgres})"
  PG_OLD_VERSION="$(sun.installed_version postgresql-${postgres})"
  PG_OLD_MAJOR=$(sun.major_version "$PG_OLD_VERSION")

  if [[ "$PG_OLD_MAJOR" != "${postgres}" ]]; then
    echo "can't upgrade major version directly"
    exit 1
  fi

  if [[ "$PG_OLD_VERSION" != "$PG_VERSION" ]]; then
    systemctl stop postgresql

    sun.unlock "$PG_PACKAGES"
    for package in ${PG_PACKAGES}; do
      sudo apt-get install -y "$package"
    done
    sun.lock "$PG_PACKAGES"

    systemctl restart postgresql
  fi
fi
