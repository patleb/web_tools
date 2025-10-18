PG_CONFIG_FILE=$(pg.config_file)
pg_log_min_messages=${pg_log_min_messages:-error}
pg_log_lock_waits=${pg_log_lock_waits:-on}
pg_hot_standby=${pg_hot_standby:-off}

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'log_min_messages =' %>
echo "log_min_messages = ${pg_log_min_messages}" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'log_lock_waits =' %>
echo "log_lock_waits = ${pg_log_lock_waits}" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'hot_standby =' %>
echo "hot_standby = ${pg_hot_standby}" >> "$PG_CONFIG_FILE"

# https://github.com/timescale/timescaledb-tune/blob/main/pkg/pgtune/misc.go#L24
# https://github.com/timescale/timescaledb-tune/blob/main/pkg/tstune/tuner_test.go#L1452
<% %w(
  shared_buffers
  effective_cache_size
  maintenance_work_mem
  work_mem
  max_worker_processes
  max_parallel_workers_per_gather
  max_parallel_workers
  max_parallel_maintenance_workers
  wal_buffers
  min_wal_size
  max_wal_size
    default_statistics_target
    random_page_cost
    checkpoint_completion_target
    max_connections
    autovacuum_max_workers
    autovacuum_naptime
    max_locks_per_transaction
    effective_io_concurrency
    default_toast_compression
    jit
  io_method
  synchronous_commit
  full_page_writes
  fsync
  huge_pages
  log_checkpoints
  restore_command
).each do |config| -%>
  pg_<%= config %>=${pg_<%= config %>:-nil}

  if [[ "${pg_<%= config %>}" != 'nil' ]]; then
    <%= Sh.delete_lines! '$PG_CONFIG_FILE', "#{config} =" %>
    echo "<%= config %> = ${pg_<%= config %>}" >> "$PG_CONFIG_FILE"
  fi
<% end -%>

if [[ ! -z "$(pg.shared_preload_libraries)" ]]; then
  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'shared_preload_libraries =' %>
  echo "shared_preload_libraries = '$(pg.shared_preload_libraries)'" >> "$PG_CONFIG_FILE"
fi

<% if sun.pg_stat_statements -%>
  pg_log_min_duration=${pg_log_min_duration:-2000}
  pg_stat_statements_track=${pg_stat_statements_track:-all}
  pg_stat_statements_max=${pg_stat_statements_max:-10000}
  pg_track_activity_query_size=${pg_track_activity_query_size:-2048}

  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'log_min_duration_statement =' %>
  echo "log_min_duration_statement = ${pg_log_min_duration}" >> "$PG_CONFIG_FILE"

  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'pg_stat_statements.track =' %>
  echo "pg_stat_statements.track = ${pg_stat_statements_track}" >> "$PG_CONFIG_FILE"

  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'pg_stat_statements.max =' %>
  echo "pg_stat_statements.max = ${pg_stat_statements_max}" >> "$PG_CONFIG_FILE"

  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'track_activity_query_size =' %>
  echo "track_activity_query_size = ${pg_track_activity_query_size}" >> "$PG_CONFIG_FILE"
<% end -%>

pg.restart_force
