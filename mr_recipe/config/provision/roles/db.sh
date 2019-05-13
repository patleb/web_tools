<% @sun.role_recipes(%W(
  bootstrap/all
  user/deployer
  db/sqlite
  db/postgres__POSTGRES__
  ruby/system__APT_RUBY__
  utils/all
)) do |name, id| %>

  sun.source_recipe "<%= name %>" <%= id %>

<% end %>
