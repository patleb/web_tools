source helpers.sh

sun.setup_commands
sun.setup_system_globals
sun.setup_attributes

export SCRIPT_DONE=false
export SCRIPT_START=$(sun.current_time)

trap sun.script_ensure EXIT

if [[ "${debug}" == 'trace' ]]; then
  set -x
fi

echo.started "Script [${script}]"

sun.include "roles/deploy_before.sh"
