export REBOOT_RECIPE=true
if [[ "$REBOOT_FORCE" == false ]]; then
  sun.include "roles/${__ROLE__}_after.sh"
fi

REBOOT_LINE='Done [reboot]'
if [[ ! $(grep -Fx "$REBOOT_LINE" "$HOME/$__MANIFEST_LOG__") ]]; then
  sun.done "reboot"
fi

if [[ "$__ENV__" != 'vagrant' ]]; then
  case "$OS" in
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
