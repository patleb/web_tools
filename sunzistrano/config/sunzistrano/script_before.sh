source helpers.sh

sun.setup_commands
sun.setup_system_globals
sun.setup_attributes

export SCRIPT_DONE=false
export SCRIPT_START=$(sun.current_time)
export BASH_OUTPUT=${BASH_OUTPUT:-false}
export helper=${helper:-''}

trap sun.script_ensure EXIT

if [[ "${debug}" == 'trace' ]]; then
  set -x
fi

if [[ "$BASH_OUTPUT" == true || "${debug}" != false ]]; then
  if [[ ! -z "${helper}" ]]; then
    echo.started "Script [${script}-${helper}]"
  else
    echo.started "Script [${script}]"
  fi
fi

sun.include "roles/deploy_before.sh"
