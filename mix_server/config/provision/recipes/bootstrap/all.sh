<% sun.list_recipes(%W(
  empty_file
  upgrade__UPGRADE__
  time_locale
  filesystem
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
