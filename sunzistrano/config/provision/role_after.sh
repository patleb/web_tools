if [[ "$REBOOT_RECIPE" == false ]]; then
  $file="roles/${__ROLE__}_after.sh" && test -f $file && source $file
fi

if [[ "$__REBOOT__" == true ]]; then
  export REBOOT_FORCE=true
  source recipes/reboot.sh
fi
