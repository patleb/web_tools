<% @sun.list_recipes(%W(
  engine__DOCKER__
  compose__DOCKER_COMPOSE__
  logrotate
  postgres
  ctop__DOCKER_CTOP__
  portainer
), base: 'docker') do |name, id| %>

  sun.source_recipe "<%= name %>" <%= id %>

<% end %>
