<% sun.role_recipes(*%W(
  bootstrap/all
  user/deployer
  db/postgres__POSTGRES__
  #{'db/postgres__POSTGRES__/pg_repack' if sun.pgrepack_enabled}
  nginx/passenger
  nginx/htpasswd
  #{'ssl/ca' unless sun.nginx_skip_ssl}
  #{'ssl/self_signed' unless sun.nginx_skip_ssl}
  #{'ssl/dhparam' unless sun.nginx_skip_ssl}
  lang/ruby/system__RUBY__
  lang/nodejs/system__NODEJS__
  lang/python/system__PYTHON__
  #{'addons/pgrest__PGREST__' if sun.pgrest_enabled}
  #{'addons/gis_packages' if sun.postgis_enabled}
  #{'db/postgres__POSTGRES__/postgis__POSTGIS__' if sun.postgis_enabled}
  #{'db/postgres__POSTGRES__/timescaledb' if sun.timescaledb_enabled}
  #{'db/postgres__POSTGRES__/tune' unless sun.timescaledb_enabled}
  db/postgres__POSTGRES__/config
  utils/all
  lang/ruby/app__RBENV_RUBY__
)) do |name, id| -%>
  sun.source_recipe "<%= name %>" <%= id %>
<% end -%>
