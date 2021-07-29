### TODO read replica
# https://github.com/citusdata/pg_auto_failover
# https://github.com/pgbackrest
# https://github.com/reorg/pg_repack
# https://www.modio.se/scaling-past-the-single-machine.html
# https://askubuntu.com/questions/732431/how-to-uninstall-specific-versions-of-postgres
__LOCALE__=${__LOCALE__:-en_US}
PG_MANIFEST=$(sun.manifest_path 'postgresql')
PG_DATA_DIR=$(sun.pg_default_data_dir)
PG_CONFIG_FILE=$(sun.pg_default_config_file)
PG_HBA_FILE=$(sun.pg_default_hba_file)

PG_PACKAGES="postgresql-$__POSTGRES__ postgresql-server-dev-$__POSTGRES__ postgresql-common libpq-dev"

sh -c "echo 'deb [arch=$ARCH] http://apt.postgresql.org/pub/repos/apt/ $UBUNTU_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
add-apt-repository ppa:timescale/timescaledb-ppa
sun.update

PG_VERSION="$(sun.current_version postgresql-$__POSTGRES__)"

if [[ ! -s "$PG_MANIFEST" ]]; then
  sun.install "$PG_PACKAGES"
  sun.lock "$PG_PACKAGES"
  sun.install "timescaledb-tools"

  sudo su - postgres << EOF
    pg_dropcluster --stop "$__POSTGRES__" main
    pg_createcluster --locale "$__LOCALE__.UTF-8" --start "$__POSTGRES__" main <%= '-- --data-checksums' unless sun.pg_checksums == false %>
EOF
  systemctl restart postgresql

  sun.backup_compare "$PG_CONFIG_FILE"
  sun.backup_compare "$PG_HBA_FILE"
  sun.backup_move "/etc/logrotate.d/postgresql-common" 0440 root:root
  echo $PG_DATA_DIR > $(sun.metadata_path 'pg_data_dir')
else
  PG_OLD_VERSION=$(tac "$PG_MANIFEST" | grep -m 1 '.')
  PG_OLD_MAJOR=$(sun.pg_major_version "$PG_OLD_VERSION")

  systemctl stop postgresql

  sun.unlock "$PG_PACKAGES"
  sun.install "$PG_PACKAGES"
  sun.lock "$PG_PACKAGES"

  if [[ "$PG_OLD_MAJOR" != "$__POSTGRES__" ]]; then
    # pg_lsclusters
    sun.backup_compare "$PG_CONFIG_FILE"
    sun.backup_compare "$PG_HBA_FILE"
    sudo su - postgres << EOF
      pg_dropcluster --stop "$__POSTGRES__" main
      pg_upgradecluster -v "$__POSTGRES__" "$PG_OLD_MAJOR" main
      pg_dropcluster --stop "$PG_OLD_MAJOR" main
EOF
  fi

  systemctl restart postgresql
fi

echo "$PG_VERSION" >> "$PG_MANIFEST"
