PG_CONFIG_FILE=$(pg.default_config_file)
PG_HBA_FILE=$(pg.default_hba_file)
PG_ENV_FILE=$(pg.env_file)

sun.install "postgresql-common"
yes | sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sun.update

PG_VERSION="$(sun.installed_version postgresql-${postgres})"
PG_PACKAGES="postgresql-${postgres} postgresql-server-dev-${postgres}"
sun.install "$PG_PACKAGES"
sun.lock "$PG_PACKAGES"
go install github.com/timescale/timescaledb-tune/cmd/timescaledb-tune@main

sudo su - postgres << EOF
  set -eu
  pg_dropcluster --stop "${postgres}" main
  pg_createcluster --port="543$((postgres % 10))" --locale "$LC" --start "${postgres}" main <%= '-- --no-data-checksums' if sun.pg_checksums == false %>
EOF
sun.backup_compare "$PG_CONFIG_FILE"
sun.backup_compare "$PG_HBA_FILE"
sun.backup_compare "$PG_ENV_FILE"
sun.backup_copy "/etc/logrotate.d/postgresql-common" 0440 root:root

echo "$PG_VERSION" >> $(sun.manifest_path 'postgresql')
echo "$(pg.default_data_dir)" > $(sun.metadata_path 'pg_data_dir')

systemctl restart postgresql
psql --version
