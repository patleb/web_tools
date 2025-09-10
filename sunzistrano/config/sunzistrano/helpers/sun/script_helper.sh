sun.source_script() {
  source "scripts/$1.sh"
}

sun.script_ensure() {
  cd "${bash_dir}"
  sun.include "roles/deploy_ensure.sh"
  if [[ "$BASH_OUTPUT" != false || "${debug}" != false ]]; then
    if [[ "$BASH_OUTPUT" == true ]]; then
      sun.elapsed_time $SCRIPT_START
    fi
    if [[ "$SCRIPT_DONE" == true ]]; then
      if [[ "${script}" == 'helper' ]]; then
        echo.success "Done   [${helper}]"
      else
        echo.success "Done   [${script}]"
      fi
    else
      echo.failure 'ERROR'
    fi
  fi
  cd "$PWD_WAS"
}
