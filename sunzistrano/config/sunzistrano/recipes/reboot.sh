export REBOOT_RECIPE=true
if [[ "$REBOOT_FORCE" == false ]]; then
  sun.include "roles/${role}_after.sh"
fi

REBOOT_LINE='Done [reboot]'
if [[ ! $(grep -Fx "$REBOOT_LINE" "${manifest_log}") ]]; then
  sun.done "reboot"
fi

if [[ "${env}" != 'vagrant' ]]; then
  case "$OS_NAME" in
  ubuntu)
    echo 'Running "unattended-upgrade"'
    unattended-upgrade -d
  ;;
  esac
fi

sun.on_exit
trap - EXIT

echo 'Rebooting...'

sleep 5

reboot
