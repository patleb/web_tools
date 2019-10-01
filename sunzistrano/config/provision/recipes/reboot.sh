if [[ "$REBOOT_FORCE" == false ]]; then
  source roles/hook_after.sh
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

sun.ensure
trap - EXIT

echo 'Rebooting...'

sleep 5

reboot
