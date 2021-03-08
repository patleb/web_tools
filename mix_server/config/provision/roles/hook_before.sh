<% sun.list_helpers(Gem.root("mix_server")).each do |file| %>
  source helpers/<%= file %>
<% end %>
