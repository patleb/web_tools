### TODO
# https://docs.timescale.com/v0.10/getting-started/installation/linux/installation-apt-ubuntu
# https://github.com/pgbackrest
# https://github.com/reorg/pg_repack
# https://www.modio.se/scaling-past-the-single-machine.html
# https://askubuntu.com/questions/732431/how-to-uninstall-specific-versions-of-postgres

sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ $UBUNTU_CODENAME-pgdg main' >> /etc/apt/sources.list.d/pgdg.list"
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sun.update

# '10+191.pgdg16.04+1'
PG_VERSION="<%= @sun.postgres || "$(sun.current_version 'postgresql')" %>"
PG_MAJOR=$(sun.pg_major_version "$PG_VERSION")
PG_MANIFEST=$(sun.manifest_path 'postgresql')
PG_HOLD="postgresql-$PG_MAJOR libpq-dev postgresql postgresql-contrib postgresql-common"

if [[ ! -s "$PG_MANIFEST" ]]; then
  sun.install "postgresql-$PG_MAJOR"
  sun.install "postgresql-contrib-$PG_MAJOR"
  sun.install "libpq-dev"
  apt-mark hold $PG_HOLD

  sun.backup_compare "/etc/postgresql/$PG_MAJOR/main/postgresql.conf"
  sun.backup_compare "/etc/postgresql/$PG_MAJOR/main/pg_hba.conf"
  sun.backup_compare "/etc/postgresql/$PG_MAJOR/main/start.conf"
else
  PG_OLD_VERSION=$(tac "$PG_MANIFEST" | grep -m 1 '.')
  PG_OLD_MAJOR=$(sun.pg_major_version "$PG_OLD_VERSION")

  PG_BACKUP="$HOME/postgresql-$PG_OLD_VERSION-backup"

  sudo -u postgres pg_dumpall --clean --quote-all-identifiers > "$PG_BACKUP"

  if [[ -s "$PG_BACKUP" ]]; then
    echo "pg_dumpall backup available at $PG_BACKUP"
  else
    echo "[$PG_BACKUP] is empty"
    exit 1
  fi

  systemctl stop postgresql

  apt-mark unhold $PG_HOLD
  sun.install "postgresql-$PG_MAJOR"
  sun.install "postgresql-contrib-$PG_MAJOR"
  sun.install "libpq-dev"
  apt-mark hold $PG_HOLD

  if [[ "$PG_OLD_MAJOR" != "$PG_MAJOR" ]]; then
    # pg_lsclusters
    # ALTER USER "postgres" WITH PASSWORD 'postgres';
    sun.backup_compare "/etc/postgresql/$PG_MAJOR/main/postgresql.conf"
    sun.backup_compare "/etc/postgresql/$PG_MAJOR/main/pg_hba.conf"
    sun.backup_compare "/etc/postgresql/$PG_MAJOR/main/start.conf"
    sudo su - postgres << EOF
      pg_dropcluster --stop "$PG_MAJOR" main
      pg_upgradecluster -v "$PG_MAJOR" "$PG_OLD_MAJOR" main
      pg_dropcluster --stop "$PG_OLD_MAJOR" main
EOF
  fi

  systemctl restart postgresql
fi

echo "$PG_VERSION" >> "$PG_MANIFEST"
