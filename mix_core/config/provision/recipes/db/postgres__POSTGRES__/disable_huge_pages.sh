PG_CONF_DIR=$(sun.pg_conf_dir)

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'huge_pages' %>
echo "huge_pages = off" >> "$PG_CONF_DIR/postgresql.conf"

sun.pg_restart_force
