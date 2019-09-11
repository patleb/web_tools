<% @sun.role_recipes(*%W(
  bootstrap/all
  user/deployer
  db/postgres__POSTGRES__
  db/postgres__POSTGRES__/logrotate
  nginx/passenger
  nginx/htpasswd
  nginx/logrotate
  #{'ssl/ca' unless @sun.nginx_skip_ssl}
  #{'ssl/self_signed' unless @sun.nginx_skip_ssl}
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
