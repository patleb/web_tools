<% @sun.role_recipes(*%W(
  bootstrap/all
  user/deployer
  db/postgres__POSTGRES__
  nginx/passenger
  nginx/htpasswd
  nginx/logrotate
  ssl/ca
  ssl/self_signed
  lang/ruby/system__RUBY__
  lang/nodejs/system__NODEJS__
  lang/rust/system__RUST__
  lang/crystal/system__CRYSTAL__
  lang/python/system__PYTHON__
  utils/all
  lang/ruby/app__RBENV_RUBY__
)) do |name, id| %>

  sun.source_recipe "<%= name %>" <%= id %>

<% end %>
