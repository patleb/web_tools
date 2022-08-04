sun.start_provision() {
  if [[ -e "${manifest_log}" ]]; then
    echo "Existing provisioning"
  else
    echo "New provisioning"
    touch "${manifest_log}"
    mkdir "${manifest_dir}"
    mkdir "${metadata_dir}"
    mkdir "${defaults_dir}"
  fi
  echo "Started at $(sun.timestamp)"
}

sun.timestamp() {
  echo $(date '+%Y-%m-%d %H:%M:%S')
}

sun.current_time() {
  echo $(date -u +"%s")
}

sun.elapsed_time() {
  local start=$1
  local finish=$(sun.current_time)
  local elapsed_time=$(($finish-$start))
  echo "$(($elapsed_time / 60)) minutes and $(($elapsed_time % 60)) seconds elapsed."
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
