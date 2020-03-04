__PG_SYNCHRONOUS_COMMIT__=${__PG_SYNCHRONOUS_COMMIT__:-on}
__PG_FSYNC__=${__PG_FSYNC__:-on}
__PG_HUGE_PAGES__=${__PG_HUGE_PAGES__:-try}
# __PG_PORT__=${__PG_PORT__:-5432}
__PG_MAX_CONNECTIONS__=${__PG_MAX_CONNECTIONS__:-100}
__PG_MAX_LOCKS_PER_TRANSACTION__=${__PG_MAX_LOCKS_PER_TRANSACTION__:-64}
PG_CONFIG_FILE=$(sun.pg_config_file)

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'synchronous_commit =' %>
echo "synchronous_commit = $__PG_SYNCHRONOUS_COMMIT__" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'fsync =' %>
echo "fsync = $__PG_FSYNC__" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'huge_pages =' %>
echo "huge_pages = $__PG_HUGE_PAGES__" >> "$PG_CONFIG_FILE"

<%# Sh.delete_lines! '$PG_CONFIG_FILE', 'port =' %>
# echo "port = $__PG_PORT__" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'max_connections =' %>
echo "max_connections = $__PG_MAX_CONNECTIONS__" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'max_locks_per_transaction =' %>
echo "max_locks_per_transaction = $__PG_MAX_LOCKS_PER_TRANSACTION__" >> "$PG_CONFIG_FILE"

sun.pg_restart_force
