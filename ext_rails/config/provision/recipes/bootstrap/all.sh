<% sun.list_recipes(%W(
  upgrade__UPGRADE__
  time_locale
  mount
  swap__SWAP_SIZE__
  nofile
  packages
  #{'unattended_upgrade' if sun.os.centos?}
  ssh
  firewall
  firewall/deny_mail
  fail2ban
), base: 'bootstrap') do |name, id| -%>
  sun.source_recipe "<%= name %>" <%= id %>
<% end -%>
