__PG_MAX_CONNECTIONS__=${__PG_MAX_CONNECTIONS__:-100}
PG_CONF_DIR=$(sun.pg_conf_dir)

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'max_connections' %>
echo "max_connections = $__PG_MAX_CONNECTIONS__" >> "$PG_CONF_DIR/postgresql.conf"

systemctl restart postgresql
