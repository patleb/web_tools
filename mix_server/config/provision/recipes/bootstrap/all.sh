<% sun.list_recipes(%W(
  empty_file
  upgrade__UPGRADE__
  time_locale
  mount
  swap__SWAP_SIZE__
  nofile
  packages
  ssh
  firewall
  firewall/deny_mail
  fail2ban
  fail2ban/logrotate
  logrotate
  osquery
), base: 'bootstrap') do |name, id| -%>
  sun.source_recipe "<%= name %>" <%= id %>
<% end -%>
