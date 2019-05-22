<% @sun.role_recipes(%W(
  bootstrap/all
  user/deployer
  db/postgres__POSTGRES__
  nginx/passenger
  nginx/htpasswd
  nginx/logrotate
  ssl/ca
  #{@sun.env.vagrant? ? 'ssl/self_signed' : 'ssl/cerbot'}
  ruby/system__OS_RUBY__
  nodejs/system__OS_NODEJS__
  utils/all
  ruby/app__RBENV_RUBY__
)) do |name, id| %>

  sun.source_recipe "<%= name %>" <%= id %>

<% end %>
