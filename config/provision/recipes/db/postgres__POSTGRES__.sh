### TODO
# https://github.com/pgbackrest
# https://github.com/reorg/pg_repack
# https://www.modio.se/scaling-past-the-single-machine.html
# https://askubuntu.com/questions/732431/how-to-uninstall-specific-versions-of-postgres
PG_MAJOR="<%= @sun.postgres %>"
PG_MANIFEST=$(sun.manifest_path 'postgresql')

case "$OS" in
ubuntu)
  PG_PACKAGES="postgresql-$PG_MAJOR postgresql postgresql-contrib postgresql-common libpq-dev"
  PG_CONF_DIR="/etc/postgresql/$PG_MAJOR/main"

  sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ $UBUNTU_CODENAME-pgdg main' >> /etc/apt/sources.list.d/pgdg.list"
  wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
  sun.update

  PG_VERSION="$(sun.current_version postgresql-$PG_MAJOR)"
;;
centos)
  PG_PACKAGES="postgresql$PG_MAJOR-server postgresql$PG_MAJOR postgresql$PG_MAJOR-contrib postgresql$PG_MAJOR-devel"
  PG_CONF_DIR="/var/lib/pgsql/$PG_MAJOR/data"

  yes | yum localinstall --nogpgcheck "https://yum.postgresql.org/$PG_MAJOR/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"

  PG_VERSION="$(sun.current_version postgresql$PG_MAJOR)"
;;
esac

if [[ ! -s "$PG_MANIFEST" ]]; then
  sun.install "$PG_PACKAGES"
  sun.lock "$PG_PACKAGES"

  case "$OS" in
  ubuntu)
    sun.backup_compare "$PG_CONF_DIR/postgresql.conf"
    sun.backup_compare "$PG_CONF_DIR/pg_hba.conf"
  ;;
  centos)
    /usr/pgsql-$PG_MAJOR/bin/postgresql-$PG_MAJOR-setup initdb
    sun.backup_compare "$PG_CONF_DIR/postgresql.conf"
    sun.backup_compare "$PG_CONF_DIR/pg_hba.conf"
    echo 'Alias=postgresql.service' >> /usr/lib/systemd/system/postgresql-$PG_MAJOR.service
    systemctl enable postgresql-$PG_MAJOR
    systemctl start postgresql
  ;;
  esac
else
  case "$OS" in
  centos)
    # TODO centos
    echo "postgres upgrade not supported on CentOS"
    exit 1
  ;;
  esac

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

  sun.unlock "$PG_PACKAGES"
  sun.install "$PG_PACKAGES"
  sun.lock "$PG_PACKAGES"

  if [[ "$PG_OLD_MAJOR" != "$PG_MAJOR" ]]; then
    # pg_lsclusters
    # ALTER USER "postgres" WITH PASSWORD 'postgres';
    sun.backup_compare "$PG_CONF_DIR/postgresql.conf"
    sun.backup_compare "$PG_CONF_DIR/pg_hba.conf"
    sudo su - postgres << EOF
      pg_dropcluster --stop "$PG_MAJOR" main
      pg_upgradecluster -v "$PG_MAJOR" "$PG_OLD_MAJOR" main
      pg_dropcluster --stop "$PG_OLD_MAJOR" main
EOF
  fi

  systemctl restart postgresql
fi

echo "$PG_VERSION" >> "$PG_MANIFEST"
