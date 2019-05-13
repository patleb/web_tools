<% @sun.role_helpers(MrRecipe.root).each do |file| %>
  source helpers/<%= file %>
<% end %>
