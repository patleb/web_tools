<% sun.list_recipes(%W(
  packages
  htop
  goaccess
  monit
  parallel
  sysstat
  #{'mailcatcher' if sun.env.vagrant?}
), base: 'utils') do |name, id| -%>
  sun.source_recipe "<%= name %>" <%= id %>
<% end -%>
