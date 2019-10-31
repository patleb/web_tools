__PG_MAX_LOCKS_PER_TRANSACTION__=${__PG_MAX_LOCKS_PER_TRANSACTION__:-64}
PG_CONF_DIR=$(sun.pg_conf_dir)

<%= Sh.delete_lines! '$PG_CONF_DIR/postgresql.conf', 'max_locks_per_transaction' %>
echo "max_locks_per_transaction = $__PG_MAX_LOCKS_PER_TRANSACTION__" >> "$PG_CONF_DIR/postgresql.conf"

systemctl restart postgresql
