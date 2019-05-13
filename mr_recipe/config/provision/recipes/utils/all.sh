<% @sun.list_recipes(%W(
  packages
  crystal
  goaccess
  monit
  rust
  sysstat
  benchmark/cryload
  #{'mailcatcher' if @sun.env.vagrant?}
), base: 'utils') do |name, id| %>

  sun.source_recipe "<%= name %>" <%= id %>

<% end %>
