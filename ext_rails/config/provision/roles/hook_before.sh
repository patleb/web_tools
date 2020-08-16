<% sun.list_helpers(Gem.root("ext_rails")).each do |file| %>
  source helpers/<%= file %>
<% end %>
