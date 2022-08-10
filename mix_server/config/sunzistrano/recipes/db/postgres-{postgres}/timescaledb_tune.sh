PG_CONFIG_FILE=$(pg.config_file)

sed -rzi -- "s/# TIMESCALEDB START.*# TIMESCALEDB END\n//g" $PG_CONFIG_FILE

echo "# TIMESCALEDB START" >> $PG_CONFIG_FILE
timescaledb-tune --conf-path=$PG_CONFIG_FILE --quiet --yes --dry-run >> $PG_CONFIG_FILE
echo "timescaledb.telemetry_level=off" >> $PG_CONFIG_FILE
echo "# TIMESCALEDB END" >> $PG_CONFIG_FILE

pg.restart_force
