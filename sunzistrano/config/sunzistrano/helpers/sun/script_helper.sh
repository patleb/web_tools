sun.script_ensure() {
  cd "${bash_dir}"
  sun.include "roles/deploy_ensure.sh"
  sun.elapsed_time $SCRIPT_START
  if [[ "$SCRIPT_DONE" == true ]]; then
    echo.green "[$(sun.timestamp)] Done   [${script}]"
  else
    echo.red "[$(sun.timestamp)] ERROR"
  fi
  cd "$PWD_WAS"
}
