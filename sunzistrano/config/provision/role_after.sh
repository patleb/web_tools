source roles/hook_after.sh

<% if @sun.reboot %>
  REBOOT_FORCE=true
  source recipes/reboot.sh
<% end %>
