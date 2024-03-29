### TODO read replica
# https://github.com/citusdata/pg_auto_failover
# https://github.com/pgbackrest
# https://github.com/reorg/pg_repack
# https://www.modio.se/scaling-past-the-single-machine.html
# https://askubuntu.com/questions/732431/how-to-uninstall-specific-versions-of-postgres
locale=${locale:-en_US}
PG_CONFIG_FILE=$(pg.default_config_file)
PG_HBA_FILE=$(pg.default_hba_file)

sh -c "echo 'deb [arch=$ARCH] http://apt.postgresql.org/pub/repos/apt/ $UBUNTU_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $UBUNTU_CODENAME main" > /etc/apt/sources.list.d/timescaledb.list
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | apt-key add -
sun.update

PG_VERSION="$(sun.installed_version postgresql-${postgres})"
PG_PACKAGES="postgresql-${postgres} postgresql-server-dev-${postgres} postgresql-common libpq-dev"
sun.install "$PG_PACKAGES"
sun.lock "$PG_PACKAGES"
sun.install "timescaledb-tools"

sudo su - postgres << EOF
  pg_dropcluster --stop "${postgres}" main
  pg_createcluster --port="543$((postgres % 10))" --locale "${locale}.UTF-8" --start "${postgres}" main <%= '-- --data-checksums' unless sun.pg_checksums == false %>
EOF
sun.backup_compare "$PG_CONFIG_FILE"
sun.backup_compare "$PG_HBA_FILE"
sun.backup_copy "/etc/logrotate.d/postgresql-common" 0440 root:root

echo "$PG_VERSION" >> $(sun.manifest_path 'postgresql')
echo "$(pg.default_data_dir)" > $(sun.metadata_path 'pg_data_dir')

systemctl restart postgresql
