sun.setup_commands
sun.setup_system_globals
sun.setup_attributes
sun.check_os

export REBOOT_RECIPE=false
export REBOOT_FORCE=false

trap sun.recipe_ensure EXIT

sun.start_role

sun.include "roles/${role}_before.sh"
