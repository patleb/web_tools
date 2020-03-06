### TODO
# https://github.com/citusdata/pg_auto_failover
# https://github.com/pgbackrest
# https://github.com/reorg/pg_repack
# https://www.modio.se/scaling-past-the-single-machine.html
# https://askubuntu.com/questions/732431/how-to-uninstall-specific-versions-of-postgres
PG_MANIFEST=$(sun.manifest_path 'postgresql')
PG_DATA_DIR=$(sun.pg_default_data_dir)
PG_CONFIG_FILE=$(sun.pg_default_config_file)
PG_HBA_FILE=$(sun.pg_default_hba_file)

case "$OS" in
ubuntu)
  PG_PACKAGES="postgresql-$__POSTGRES__ postgresql-server-dev-$__POSTGRES__ postgresql-common libpq-dev"

  sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ $UBUNTU_CODENAME-pgdg main' >> /etc/apt/sources.list.d/pgdg.list"
  wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
  sun.update

  PG_VERSION="$(sun.current_version postgresql-$__POSTGRES__)"
;;
centos)
  PG_PACKAGES="postgresql$__POSTGRES__-server postgresql$__POSTGRES__ postgresql$__POSTGRES__-contrib postgresql$__POSTGRES__-devel"

  yes | yum localinstall --nogpgcheck "https://yum.postgresql.org/$__POSTGRES__/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"

  PG_VERSION="$(sun.current_version postgresql$__POSTGRES__)"
;;
esac

if [[ ! -s "$PG_MANIFEST" ]]; then
  sun.install "$PG_PACKAGES"
  sun.lock "$PG_PACKAGES"

  case "$OS" in
  ubuntu)
    sun.backup_compare "$PG_CONFIG_FILE"
    sun.backup_compare "$PG_HBA_FILE"
  ;;
  centos)
    echo "export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/pgsql-$__POSTGRES__/bin" >> /etc/environment
    export PATH="$PATH:/usr/pgsql-$__POSTGRES__/bin"

    postgresql-$__POSTGRES__-setup initdb
    sun.backup_compare "$PG_CONFIG_FILE"
    sun.backup_move "$PG_HBA_FILE"
    chmod 600 "$PG_HBA_FILE"
    chown postgres:postgres "$PG_HBA_FILE"
    echo 'Alias=postgresql.service' >> /usr/lib/systemd/system/postgresql-$__POSTGRES__.service
    systemctl enable postgresql-$__POSTGRES__
    systemctl restart postgresql
    sun.psql "ALTER USER postgres WITH PASSWORD 'postgres'"
  ;;
  esac
  echo $PG_DATA_DIR > $(sun.metadata_path 'pg_data_dir')
else
  case "$OS" in
  centos)
    echo "postgres upgrade is not yet supported on CentOS"
    exit 1
  ;;
  esac

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
