desc() {
  echo.lightgray "[$(sun.timestamp)] $@"
}

echo.info() {
  echo "[$(sun.timestamp)] $@"
}

cd.back() {
  cd - > /dev/null
}

sun.start_provision() {
  local provisioning='provisioning'
  if [[ "${deploy}" == true ]]; then
    provisioning='deployment'
  fi
  if [[ -e "${manifest_log}" ]]; then
    echo.info "Existing ${provisioning}"
  else
    echo.info "New ${provisioning}"
    touch "${manifest_log}"
    mkdir "${manifest_dir}"
    mkdir "${metadata_dir}"
    mkdir "${defaults_dir}"
  fi
}

sun.standard_time() {
  echo $(date +%FT%T%z) # YYYY-MM-DDTHH:MM:SS+ZZZZ
}

sun.nanoseconds() {
  echo $(date +%s%N)
}

sun.timestamp() {
  echo $(date '+%Y-%m-%d %H:%M:%S %Z')
}

sun.current_time() {
  echo $(date -u +"%s")
}

sun.elapsed_time() {
  local start=$1
  local finish=$(sun.current_time)
  local elapsed_time=$(($finish-$start))
  local minutes=$(($elapsed_time / 60))
  local seconds=$(($elapsed_time % 60))
  if [[ "$minutes" != 0 || "$seconds" != 0 ]]; then
    echo "$minutes minutes and $seconds seconds elapsed."
  else
    echo 'less than 1 second elapsed'
  fi
}

sun.flatten_path() {
  echo "$(echo "$1" | sed 's|/|~|g')"
}

sun.include() {
  if [[ -f "$1" ]]; then
    source "$1"
  fi
}

sun.remove_missing_files() {
  local all_files=($1)
  local kept_files=($2)
  for file in "${all_files[@]}"; do
    local remove=true
    for kept in "${kept_files[@]}"; do
      if [[ $file == $kept ]]; then
        remove=false
      fi
    done
    if [[ $remove == true ]]; then
      rm -rf $file
    fi
  done
}
