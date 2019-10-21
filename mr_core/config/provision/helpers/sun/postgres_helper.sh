sun.pg_major_version() {
  local version="$1"
  IFS='.' read -ra version <<< "$version"
  if sun.version_is_smaller "$version" "10"; then
    echo "${version[0]}.$(echo ${version[1]} | sed -r 's/^([0-9]+).*/\1/')"
  else
    echo "$(echo ${version[0]} | sed -r 's/^([0-9]+).*/\1/')"
  fi
}

sun.pg_conf_dir() {
  sun.psql 'SHOW data_directory'
}

sun.psql() {
  sudo su - postgres << EOF | head -n1
    psql -d postgres -tAc "$1"
EOF
}
