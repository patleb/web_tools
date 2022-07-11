sun.initialize() {
  if [[ -e "$HOME/$__MANIFEST_LOG__" ]]; then
    echo "Provisioning already started"
  else
    echo "New provisioning"
    touch "$HOME/$__MANIFEST_LOG__"
    mkdir "$HOME/$__MANIFEST_DIR__"
    mkdir "$HOME/$__METADATA_DIR__"
    mkdir "$HOME/$__DEFAULTS_DIR__"
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

sun.provision_path() {
  echo "$HOME/$__PROVISION_DIR__"
}
