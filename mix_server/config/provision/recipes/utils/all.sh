<% sun.list_recipes(%W(
  packages
  htop
  #{'mailcatcher' if sun.env.vagrant?}
  parallel
), base: 'utils') do |name, id| -%>
  sun.source_recipe "<%= name %>" <%= id %>
<% end -%>
