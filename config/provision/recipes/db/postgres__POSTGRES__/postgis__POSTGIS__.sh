PG_MAJOR="<%= @sun.postgres %>"
PGIS_MAJOR="<%= @sun.postgis %>"

case "$OS" in
ubuntu)
  # TODO https://kitcharoenp.github.io/postgresql/postgis/2018/05/28/set_up_postgreSQL_postgis.html
  PG_CONF_DIR="/etc/postgresql/$PG_MAJOR/main"
  PGIS_PACKAGES="postgresql-$PG_MAJOR-postgis-$PGIS_MAJOR postgresql-$PG_MAJOR-postgis-scripts"
;;
centos)
  PG_CONF_DIR="/var/lib/pgsql/$PG_MAJOR/data"
  PGIS_PACKAGES="postgis$(echo $PGIS_MAJOR | tr -d '.')_$PG_MAJOR"
;;
esac

sun.update
sun.install "$PGIS_PACKAGES"
sun.lock "$PGIS_PACKAGES"
