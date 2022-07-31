source helpers.sh

sun.setup_commands
sun.setup_system_globals
sun.setup_attributes
sun.check_os

export REBOOT_RECIPE=false
export REBOOT_FORCE=false
export ROLE_START=$(sun.current_time)

trap sun.recipe_ensure EXIT

sun.start_provision

if [[ "${debug}" == 'trace' ]]; then
  set -x
fi

sun.include "roles/${role}_before.sh"
