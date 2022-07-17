sun.initialize() {
  if [[ -e "$HOME/${manifest_log}" ]]; then
    echo "Provisioning already started"
  else
    echo "New provisioning"
    touch "$HOME/${manifest_log}"
    mkdir "$HOME/${manifest_dir}"
    mkdir "$HOME/${metadata_dir}"
    mkdir "$HOME/${defaults_dir}"
  fi
  echo "Started at $(date '+%Y-%m-%d %H:%M:%S')"
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

sun.bash_path() {
  echo "$HOME/${bash_dir}"
}

sun.include() {
  if [[ -f "$1" ]]; then
    source "$1"
  fi
}
