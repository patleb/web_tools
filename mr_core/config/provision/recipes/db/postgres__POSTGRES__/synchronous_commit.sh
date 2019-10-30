PG_CONF_DIR=$(sun.pg_conf_dir)

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'synchronous_commit' %>
echo "synchronous_commit = off" >> "$PG_CONF_DIR/postgresql.conf"

systemctl restart postgresql
