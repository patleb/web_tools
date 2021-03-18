if [[ "$REBOOT_RECIPE" == false ]]; then
  source roles/hook_after.sh
fi

if [[ "$__REBOOT__" == true ]]; then
  export REBOOT_FORCE=true
  source recipes/reboot.sh
fi
