<% sun.list_helpers(Gem.root("mr_backend")).each do |file| %>
  source helpers/<%= file %>
<% end %>
