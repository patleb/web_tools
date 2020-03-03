__PG_SYNCHRONOUS_COMMIT__=${__PG_SYNCHRONOUS_COMMIT__:-on}
__PG_FSYNC__=${__PG_FSYNC__:-on}
__PG_HUGE_PAGES__=${__PG_HUGE_PAGES__:-try}
__PG_MAX_CONNECTIONS__=${__PG_MAX_CONNECTIONS__:-100}
__PG_MAX_LOCKS_PER_TRANSACTION__=${__PG_MAX_LOCKS_PER_TRANSACTION__:-64}
PG_CONF_DIR=$(sun.pg_conf_dir)

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'synchronous_commit' %>
echo "synchronous_commit = $__PG_SYNCHRONOUS_COMMIT__" >> "$PG_CONF_DIR/postgresql.conf"

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'fsync' %>
echo "fsync = $__PG_FSYNC__" >> "$PG_CONF_DIR/postgresql.conf"

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'huge_pages' %>
echo "huge_pages = $__PG_HUGE_PAGES__" >> "$PG_CONF_DIR/postgresql.conf"

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'max_connections' %>
echo "max_connections = $__PG_MAX_CONNECTIONS__" >> "$PG_CONF_DIR/postgresql.conf"

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'max_locks_per_transaction' %>
echo "max_locks_per_transaction = $__PG_MAX_LOCKS_PER_TRANSACTION__" >> "$PG_CONF_DIR/postgresql.conf"

sun.pg_restart_force
