PG_MAJOR="<%= @sun.postgres %>"

# TODO
# https://github.com/timescale/timescaledb/issues/515
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/tuning_and_optimizing_red_hat_enterprise_linux_for_oracle_9i_and_10g_databases/sect-oracle_9i_and_10g_tuning_guide-setting_shared_memory-setting_shmall_parameter
case "$OS" in
ubuntu)
  PG_CONF_DIR="/etc/postgresql/$PG_MAJOR/main"

  add-apt-repository ppa:timescale/timescaledb-ppa
;;
centos)
  PG_CONF_DIR="/var/lib/pgsql/$PG_MAJOR/data"

  cat > /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/7/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL
;;
esac

sun.update
sun.install "timescaledb-postgresql-$PG_MAJOR"
sun.lock "timescaledb-postgresql-$PG_MAJOR"
timescaledb-tune --quiet --yes --dry-run >> "$PG_CONF_DIR/postgresql.conf"
echo "timescaledb.telemetry_level=off" >> "$PG_CONF_DIR/postgresql.conf"
systemctl restart postgresql
