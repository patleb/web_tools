# TODO https://kitcharoenp.github.io/postgresql/postgis/2018/05/28/set_up_postgreSQL_postgis.html
PGIS_PACKAGES="postgresql-${postgres}-postgis-${postgis} postgresql-${postgres}-postgis-${postgis}-scripts"

sun.update
sun.install "$PGIS_PACKAGES"
sun.lock "$PGIS_PACKAGES"
