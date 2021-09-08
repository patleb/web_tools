<% sun.list_recipes(%W(
  upgrade__UPGRADE__
  time_locale
  files
  swap__SWAP_SIZE__
  limits
  packages
  ssh
  firewall
  firewall/deny_mail
  fail2ban
  osquery
  clamav
), base: 'bootstrap') do |name, id| -%>
  sun.source_recipe "<%= name %>" <%= id %>
<% end -%>
