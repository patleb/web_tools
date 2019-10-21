PG_CONF_DIR=$(sun.pg_conf_dir)
PG_CONF="$PG_CONF_DIR/postgresql.conf"

sed -rzi -- "s/# TIMESCALEDB START.*# TIMESCALEDB END\n//g" $PG_CONF

echo "# TIMESCALEDB START" >> $PG_CONF
timescaledb-tune --conf-path=$PG_CONF --quiet --yes --dry-run >> $PG_CONF
echo "timescaledb.telemetry_level=off" >> $PG_CONF
echo "# TIMESCALEDB END" >> $PG_CONF

systemctl restart postgresql
