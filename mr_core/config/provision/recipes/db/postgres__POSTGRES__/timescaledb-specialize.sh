PG_CONF_DIR=$(sun.pg_conf_dir)

sed -rzi -- "s/# TIMESCALEDB START.*# TIMESCALEDB END\n//g" "$PG_CONF_DIR/postgresql.conf"

echo "# TIMESCALEDB START" >> "$PG_CONF_DIR/postgresql.conf"
timescaledb-tune --quiet --yes --dry-run >> "$PG_CONF_DIR/postgresql.conf"
echo "timescaledb.telemetry_level=off" >> "$PG_CONF_DIR/postgresql.conf"
echo "# TIMESCALEDB END" >> "$PG_CONF_DIR/postgresql.conf"

systemctl restart postgresql
