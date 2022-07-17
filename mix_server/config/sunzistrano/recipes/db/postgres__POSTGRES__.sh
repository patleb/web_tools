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

PG_PACKAGES="postgresql-${postgres} postgresql-server-dev-${postgres} postgresql-common libpq-dev"

sh -c "echo 'deb [arch=$ARCH] http://apt.postgresql.org/pub/repos/apt/ $UBUNTU_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $UBUNTU_CODENAME main" > /etc/apt/sources.list.d/timescaledb.list
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | apt-key add -
sun.update

PG_VERSION="$(sun.installed_version postgresql-${postgres})"

if [[ ! -s "$PG_MANIFEST" ]]; then
  sun.install "$PG_PACKAGES"
  sun.lock "$PG_PACKAGES"
  sun.install "timescaledb-tools"

  sudo su - postgres << EOF
    pg_dropcluster --stop "${postgres}" main
    pg_createcluster --locale "${locale}.UTF-8" --start "${postgres}" main <%= '-- --data-checksums' unless sun.pg_checksums == false %>
EOF
  systemctl restart postgresql

  sun.backup_compare "$PG_CONFIG_FILE"
  sun.backup_compare "$PG_HBA_FILE"
  sun.backup_move "/etc/logrotate.d/postgresql-common" 0440 root:root
  echo $PG_DATA_DIR > $(sun.metadata_path 'pg_data_dir')
else
  PG_OLD_VERSION=$(tac "$PG_MANIFEST" | grep -m 1 '.')
  PG_OLD_MAJOR=$(sun.major_version "$PG_OLD_VERSION")

  systemctl stop postgresql

  sun.unlock "$PG_PACKAGES"
  sun.install "$PG_PACKAGES"
  sun.lock "$PG_PACKAGES"

  if [[ "$PG_OLD_MAJOR" != "${postgres}" ]]; then
    # pg_lsclusters
    sun.backup_compare "$PG_CONFIG_FILE"
    sun.backup_compare "$PG_HBA_FILE"
    sudo su - postgres << EOF
      pg_dropcluster --stop "${postgres}" main
      pg_upgradecluster -v "${postgres}" "$PG_OLD_MAJOR" main
      pg_dropcluster --stop "$PG_OLD_MAJOR" main
EOF
  fi

  systemctl restart postgresql
fi

echo "$PG_VERSION" >> "$PG_MANIFEST"
