sun.shared_preload_libraries() {
  echo '<%= { pg_stat_statements: sun.pgstats_enabled, timescaledb: sun.timescaledb_enabled }.select{ |_, v| v }.keys.join(',') %>'
}

sun.pg_restart_force() {
  if ! systemctl restart postgresql; then
    systemctl reset-failed postgresql
    systemctl start postgresql
  fi
}

sun.pg_default_hba_file() {
  echo "/etc/postgresql/${postgres}/main/pg_hba.conf"
}

sun.pg_hba_file() {
  sun.psql 'SHOW hba_file'
}

sun.pg_default_config_file() {
  echo "/etc/postgresql/${postgres}/main/postgresql.conf"
}

sun.pg_config_file() {
  sun.psql 'SHOW config_file'
}

sun.pg_default_data_dir() {
  echo "/var/lib/postgresql/${postgres}/main"
}

sun.pg_data_dir() {
  sun.psql 'SHOW data_directory'
}

sun.pg_default_url() {
  echo "postgresql://${db_username}:${db_password}@${db_host:-127.0.0.1}:${db_port:-5432}/${db_database}"
}

sun.psql() {
  local cmd="$1"
  sudo -u postgres psql -d postgres -qtAb -c "$cmd" ${@: 2}
}
