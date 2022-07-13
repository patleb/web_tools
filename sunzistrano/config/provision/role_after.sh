if [[ "$REBOOT_RECIPE" == false ]]; then
  sun.include "roles/${__ROLE__}_after.sh"
fi

if [[ "$__REBOOT__" == true ]]; then
  export REBOOT_FORCE=true
  source recipes/reboot.sh
fi
