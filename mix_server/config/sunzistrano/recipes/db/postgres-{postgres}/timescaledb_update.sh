# TODO more flexible recipe or less dependent on pg_default_url --> doesn't work on new machine
TIMESCALEDB="timescaledb-2-postgresql-${postgres}"

sun.unlock $TIMESCALEDB
sun.update
sun.install $TIMESCALEDB
sun.lock $TIMESCALEDB

systemctl restart postgresql
sleep 5
sun.psql 'ALTER EXTENSION timescaledb UPDATE' -X $(sun.pg_default_url)
systemctl restart postgresql
