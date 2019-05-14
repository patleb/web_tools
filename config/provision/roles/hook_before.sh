<% @sun.role_helpers(Gem.root("mr_system")).each do |file| %>
  source helpers/<%= file %>
<% end %>
