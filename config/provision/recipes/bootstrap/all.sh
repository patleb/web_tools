<% @sun.list_recipes(%W(
  upgrade__UPGRADE__
  time_locale
  mount
  swap
  nofile
  packages
  #{'backports' if @sun.os.ubuntu?}
  ssh
  firewall
  firewall/deny_mail
), base: 'bootstrap') do |name, id| %>

  sun.source_recipe "<%= name %>" <%= id %>

<% end %>
