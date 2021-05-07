### References
# https://hunleyd.github.io/posts/PostgreSQL-logging-strftime-and-you
cat >> "$(sun.pg_config_file)" << EOF
logging_collector = on
log_directory = '/var/log/postgresql/postgresql-$__POSTGRES__-main'
log_filename = 'postgresql.log.%W'
log_file_mode = 0644
log_truncate_on_rotation = on
log_rotation_size = 0
log_rotation_age = 7d
log_checkpoints = on
log_lock_waits = on
EOF

sun.pg_restart_force
