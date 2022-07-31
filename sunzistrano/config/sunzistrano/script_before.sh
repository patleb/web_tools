source helpers.sh

sun.setup_system_globals
sun.setup_attributes

export SCRIPT_START=$(sun.current_time)

trap sun.script_ensure EXIT

if [[ "${debug}" == 'trace' ]]; then
  set -x
fi

sun.include "roles/deploy_before.sh"
