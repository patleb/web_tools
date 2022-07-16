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
  echo "/etc/postgresql/$__POSTGRES__/main/pg_hba.conf"
}

sun.pg_hba_file() {
  sun.psql 'SHOW hba_file'
}

sun.pg_default_config_file() {
  echo "/etc/postgresql/$__POSTGRES__/main/postgresql.conf"
}

sun.pg_config_file() {
  sun.psql 'SHOW config_file'
}

sun.pg_default_data_dir() {
  echo "/var/lib/postgresql/$__POSTGRES__/main"
}

sun.pg_data_dir() {
  sun.psql 'SHOW data_directory'
}

sun.pg_default_url() {
  echo "postgresql://$__DB_USERNAME__:$__DB_PASSWORD__@$__DB_HOST__:5432/$__DB_DATABASE__"
}

sun.psql() {
  local cmd="$1"
  case "$#" in
  1)
    sudo su - postgres << EOF | head -n1
      psql -d postgres -tAc "$cmd"
EOF
  ;;
  2|3)
    psql -qtAb -c "$cmd" ${@:2}
  ;;
  *)
    echo "sun.psql: invalid number of arguments (1 <= args <= 3)"
    exit 1
  ;;
  esac
}
