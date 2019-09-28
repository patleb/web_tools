source roles/hook_after.sh

if [[ "$__REBOOT__" == true ]]; then
  REBOOT_FORCE=true
  source recipes/reboot.sh
fi
