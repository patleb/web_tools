<% sun.role_recipes(*%W(
  bootstrap/upgrade__UPGRADE__
  bootstrap/time_locale
  bootstrap/files
  bootstrap/swap__SWAP_SIZE__
  bootstrap/limits
  bootstrap/packages
  bootstrap/ssh
  bootstrap/firewall
  bootstrap/firewall/deny_mail
  bootstrap/fail2ban
  bootstrap/private_ip
  bootstrap/osquery
  bootstrap/clamav
  user/deployer
  db/postgres__POSTGRES__
  db/postgres__POSTGRES__/pgxnclient
  #{'db/postgres__POSTGRES__/vector' if sun.vector_enabled}
  #{'db/postgres__POSTGRES__/pg_repack' if sun.pgrepack_enabled}
  nginx/passenger
  nginx/htpasswd
  #{'ssl/ca' if sun.server_ssl}
  #{'ssl/self_signed' if sun.server_ssl}
  #{'ssl/dhparam' if sun.server_ssl}
  lang/ruby/system__RUBY__
  lang/nodejs/system__NODEJS__
  lang/python/system__PYTHON__
  #{'addons/pgrest__PGREST__' if sun.pgrest_enabled}
  #{'addons/gis_packages' if sun.postgis_enabled}
  #{'db/postgres__POSTGRES__/postgis__POSTGIS__' if sun.postgis_enabled}
  #{'db/postgres__POSTGRES__/timescaledb' if sun.timescaledb_enabled}
  #{'db/postgres__POSTGRES__/tune' unless sun.timescaledb_enabled}
  db/postgres__POSTGRES__/config
  utils/packages
  utils/htop
  #{'utils/mailcatcher' if sun.env.vagrant?}
  utils/parallel
  lang/ruby/app__RBENV_RUBY__
)) do |name, id| -%>
  sun.source_recipe "<%= name %>" <%= id %>
<% end -%>
