# compare manually with https://pgtune.leopard.in.ua and adjust through db/postgres-{postgres}/config
# https://www.reddit.com/r/PostgreSQL/comments/pt7wxk/psa_postgresql_13_has_jit_enabled_by_default_but/
# https://www.reddit.com/r/PostgreSQL/comments/qtsif5/cascade_of_doom_jit_and_how_a_postgres_update_led/
PG_CONFIG_FILE=$(pg.config_file)

sed -rzi -- "s/# TUNE START.*# TUNE END\n//g" $PG_CONFIG_FILE

echo "# TUNE START" >> $PG_CONFIG_FILE
timescaledb-tune --conf-path=$PG_CONFIG_FILE --quiet --yes --dry-run >> $PG_CONFIG_FILE
<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'timescaledb' %>
echo "# TUNE END" >> $PG_CONFIG_FILE

pg.restart_force
