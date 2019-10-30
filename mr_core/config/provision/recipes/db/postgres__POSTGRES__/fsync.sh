PG_CONF_DIR=$(sun.pg_conf_dir)

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'fsync' %>
echo "fsync = off" >> "$PG_CONF_DIR/postgresql.conf"

sleep 5
systemctl restart postgresql
