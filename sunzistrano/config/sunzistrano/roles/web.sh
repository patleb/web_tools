<% sun.role_recipes(*%W(
  deploy
  deploy/start-{system}
  deploy/started
  deploy/update
  deploy/updated
  deploy/publish
  deploy/published
  deploy/finish
  deploy/finished
)) do |name, id| -%>
  sun.source_recipe "<%= name %>" <%= id %>
<% end -%>
