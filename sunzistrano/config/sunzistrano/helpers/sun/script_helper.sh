sun.script_ensure() {
  cd "${bash_dir}"
  sun.include "roles/deploy_ensure.sh"
  sun.elapsed_time $SCRIPT_START
  cd "$PWD_WAS"
}
