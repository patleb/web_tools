case "$OS" in
ubuntu)
  # TODO https://kitcharoenp.github.io/postgresql/postgis/2018/05/28/set_up_postgreSQL_postgis.html
  PG_CONF_DIR="/etc/postgresql/$__POSTGRES__/main"
  PGIS_PACKAGES="postgresql-$__POSTGRES__-postgis-$__POSTGIS__ postgresql-$__POSTGRES__-postgis-scripts"
;;
centos)
  PG_CONF_DIR="/var/lib/pgsql/$__POSTGRES__/data"
  PGIS_PACKAGES="postgis$(echo $__POSTGIS__ | tr -d '.')_$__POSTGRES__"
;;
esac

sun.update
sun.install "$PGIS_PACKAGES"
sun.lock "$PGIS_PACKAGES"
