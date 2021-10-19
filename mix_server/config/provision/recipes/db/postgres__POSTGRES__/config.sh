PG_CONFIG_FILE=$(sun.pg_config_file)
__PG_LOG_MIN_MESSAGES__=${__PG_LOG_MIN_MESSAGES__:-error}
__PG_LOG_CHECKPOINTS__=${__PG_LOG_CHECKPOINTS__:-on}
__PG_LOG_LOCK_WAITS__=${__PG_LOG_LOCK_WAITS__:-on}
__PG_RESTORE_COMMAND__=${__PG_RESTORE_COMMAND__:-:}
__PG_HOT_STANDBY__=${__PG_HOT_STANDBY__:off}

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'log_min_messages =' %>
echo "log_min_messages = $__PG_LOG_MIN_MESSAGES__" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'log_checkpoints =' %>
echo "log_checkpoints = $__PG_LOG_CHECKPOINTS__" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'log_lock_waits =' %>
echo "log_lock_waits = $__PG_LOG_LOCK_WAITS__" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'restore_command =' %>
echo "restore_command = '$__PG_RESTORE_COMMAND__'" >> "$PG_CONFIG_FILE"

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'hot_standby =' %>
echo "hot_standby = $__PG_HOT_STANDBY__" >> "$PG_CONFIG_FILE"

<% %w(
  synchronous_commit
  full_page_writes
  fsync
  huge_pages
  max_locks_per_transaction
  max_connections
  shared_buffers
  effective_cache_size
  maintenance_work_mem
  checkpoint_completion_target
  wal_buffers
  default_statistics_target
  random_page_cost
  effective_io_concurrency
  work_mem
  min_wal_size
  max_wal_size
  max_worker_processes
  max_parallel_workers_per_gather
  max_parallel_workers
  max_parallel_maintenance_workers
  jit
).each do |config| -%>
  __PG_<%= config.upcase %>__=${__PG_<%= config.upcase %>__:-nil}

  if [[ "$__PG_<%= config.upcase %>__" != 'nil' ]]; then
    <%= Sh.delete_lines! '$PG_CONFIG_FILE', "#{config} =" %>
    echo "<%= config %> = $__PG_<%= config.upcase %>__" >> "$PG_CONFIG_FILE"
  fi
<% end -%>

if [[ ! -z "$(sun.shared_preload_libraries)" ]]; then
  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'shared_preload_libraries =' %>
  echo "shared_preload_libraries = '$(sun.shared_preload_libraries)'" >> "$PG_CONFIG_FILE"
fi

<% if sun.pgstats_enabled -%>
  __PG_LOG_MIN_DURATION__=${__PG_LOG_MIN_DURATION__:-2000}
  __PG_STAT_STATEMENTS_TRACK__=${__PG_STAT_STATEMENTS_TRACK__:-all}
  __PG_STAT_STATEMENTS_MAX__=${__PG_STAT_STATEMENTS_MAX__:-10000}
  __PG_TRACK_ACTIVITY_QUERY_SIZE__=${__PG_TRACK_ACTIVITY_QUERY_SIZE__:-2048}

  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'log_min_duration_statement =' %>
  echo "log_min_duration_statement = $__PG_LOG_MIN_DURATION__" >> "$PG_CONFIG_FILE"

  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'pg_stat_statements.track =' %>
  echo "pg_stat_statements.track = $__PG_STAT_STATEMENTS_TRACK__" >> "$PG_CONFIG_FILE"

  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'pg_stat_statements.max =' %>
  echo "pg_stat_statements.max = $__PG_STAT_STATEMENTS_MAX__" >> "$PG_CONFIG_FILE"

  <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'track_activity_query_size =' %>
  echo "track_activity_query_size = $__PG_TRACK_ACTIVITY_QUERY_SIZE__" >> "$PG_CONFIG_FILE"
<% end -%>

sun.pg_restart_force
