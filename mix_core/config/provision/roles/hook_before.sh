<% sun.list_helpers(Gem.root("mix_core")).each do |file| %>
  source helpers/<%= file %>
<% end %>
