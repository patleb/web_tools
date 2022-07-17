PG_CONFIG_FILE=$(sun.pg_config_file)

sed -rzi -- "s/# TUNE START.*# TUNE END\n//g" $PG_CONFIG_FILE

# compare manually with https://pgtune.leopard.in.ua and adjust through db/postgres-{postgres}/config
echo "# TUNE START" >> $PG_CONFIG_FILE
timescaledb-tune --conf-path=$PG_CONFIG_FILE --quiet --yes --dry-run >> $PG_CONFIG_FILE
<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'timescaledb' %>
echo "# TUNE END" >> $PG_CONFIG_FILE

sun.pg_restart_force
