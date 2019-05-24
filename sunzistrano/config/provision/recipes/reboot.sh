if [[ "$REBOOT_FORCE" = false ]]; then
  source roles/hook_after.sh
fi

REBOOT_LINE="<%= @sun.DONE.sub(@sun.DONE_ARG, 'reboot') %>"
if [[ ! $(grep -Fx "$REBOOT_LINE" "$HOME/<%= @sun.MANIFEST_LOG %>") ]]; then
  sun.done "reboot"
fi

<% unless @sun.env.vagrant? -%>
  case "$OS" in
  ubuntu)
    echo 'Running "unattended-upgrade"'
    unattended-upgrade -d
  ;;
  esac
<% end -%>

sun.ensure
trap - EXIT

echo 'Rebooting...'

sleep 5

reboot
