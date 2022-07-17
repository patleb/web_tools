if [[ "$REBOOT_RECIPE" == false ]]; then
  sun.include "roles/${role}_after.sh"
fi

if [[ "${reboot}" == true ]]; then
  export REBOOT_FORCE=true
  source recipes/reboot.sh
fi
