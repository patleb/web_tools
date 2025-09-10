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

if [[ "$BASH_OUTPUT" != false || "${debug}" != false ]]; then
  if [[ "${script}" == 'helper' ]]; then
    echo.started "Helper [${helper}]"
  else
    echo.started "Script [${script}]"
  fi
fi

sun.include "roles/deploy_before.sh"
