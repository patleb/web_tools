export REBOOT_RECIPE=true
if [[ "$REBOOT_FORCE" == false ]]; then
  sun.include "roles/${role}_after.sh"
fi

if [[ ! $(grep -F "Done   [reboot]" "${manifest_log}") ]]; then
  sun.done "reboot"
fi

if [[ "${env}" != 'virtual' ]]; then
  case "$OS_NAME" in
  ubuntu)
    echo 'Running "unattended-upgrade"'
    unattended-upgrade -d
  ;;
  esac
fi

sun.recipe_ensure
trap - EXIT

echo 'Rebooting...'

sleep 5

reboot
