sun.start_role() {
  export ROLE_START=$(sun.start_time)
  if [[ -e "${manifest_log}" ]]; then
    echo "Existing provisioning"
  else
    echo "New provisioning"
    touch "${manifest_log}"
    mkdir "${manifest_dir}"
    mkdir "${metadata_dir}"
    mkdir "${defaults_dir}"
  fi
  echo "Started at $(date '+%Y-%m-%d %H:%M:%S')"
  if [[ "${debug}" == 'trace' ]]; then
    set -x
  fi
}

sun.start_time() {
  echo $(date -u +"%s")
}

sun.elapsed_time() {
  local start=$1
  local finish=$(date -u +"%s")
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
