pg.shared_preload_libraries() {
  echo '<%= { pg_stat_statements: sun.pg_stat_statements }.compact_blank.keys.join(',') %>'
}

pg.restart_force() {
  if ! systemctl restart postgresql; then
    systemctl reset-failed postgresql
    systemctl start postgresql
  fi
}

pg.default_hba_file() {
  echo "/etc/postgresql/${postgres}/main/pg_hba.conf"
}

pg.hba_file() { # PUBLIC
  sun.psql 'SHOW hba_file'
}

pg.default_config_file() {
  echo "/etc/postgresql/${postgres}/main/postgresql.conf"
}

pg.config_file() { # PUBLIC
  sun.psql 'SHOW config_file'
}

pg.default_data_dir() {
  echo "/var/lib/postgresql/${postgres}/main"
}

pg.data_dir() { # PUBLIC
  sun.psql 'SHOW data_directory'
}

pg.env_file() { # PUBLIC
  echo "/etc/postgresql/${postgres}/main/environment"
}

pg.default_url() {
  local default_port=543${postgres: -1}
  echo "postgresql://${db_username}:${db_password}@${db_host:-127.0.0.1}:${db_port:-$default_port}/${db_database}"
}

sun.psql() {
  local cmd="$1"
  sudo -u postgres psql -d postgres -qtAb -c "$cmd" ${@: 2}
}
