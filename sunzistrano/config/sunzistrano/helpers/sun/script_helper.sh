sun.source_script() {
  source "scripts/$1.sh"
}

sun.script_ensure() {
  cd "${bash_dir}"
  sun.include "roles/deploy_ensure.sh"
  sun.elapsed_time $SCRIPT_START
  if [[ "$SCRIPT_DONE" == true ]]; then
    if [[ ! -z "${helper}" ]]; then
      echo.success "Done   [${script}-${helper}]"
    else
      echo.success "Done   [${script}]"
    fi
  else
    echo.failure 'ERROR'
  fi
  cd "$PWD_WAS"
}
