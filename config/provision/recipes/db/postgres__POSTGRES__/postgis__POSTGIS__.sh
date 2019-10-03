case "$OS" in
ubuntu)
  # TODO https://kitcharoenp.github.io/postgresql/postgis/2018/05/28/set_up_postgreSQL_postgis.html
  PGIS_PACKAGES="postgresql-$__POSTGRES__-postgis-$__POSTGIS__ postgresql-$__POSTGRES__-postgis-$__POSTGIS__-scripts"
;;
centos)
  PGIS_PACKAGES="postgis$(echo $__POSTGIS__ | tr -d '.')_$__POSTGRES__"
;;
esac

sun.update
sun.install "$PGIS_PACKAGES"
sun.lock "$PGIS_PACKAGES"
