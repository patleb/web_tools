<% sun.role_recipes(*%W(
  bootstrap/upgrade-{upgrade}
  bootstrap/time_locale
  bootstrap/files
  bootstrap/swap-{swap_size}
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
  db/postgres-{postgres}
  db/postgres-{postgres}/pgxnclient
  #{'db/postgres-{postgres}/vector' if sun.vector_enabled}
  #{'db/postgres-{postgres}/pg_repack' if sun.pgrepack_enabled}
  nginx/passenger
  nginx/htpasswd
  #{'ssl/ca' if sun.server_ssl}
  #{'ssl/self_signed' if sun.server_ssl}
  #{'ssl/dhparam' if sun.server_ssl}
  lang/ruby/system
  lang/nodejs/system-{nodejs}
  lang/python/system
  #{'addons/pgrest-{pgrest}' if sun.pgrest_enabled}
  #{'addons/gis_packages' if sun.postgis_enabled}
  #{'db/postgres-{postgres}/postgis-{postgis}' if sun.postgis_enabled}
  #{'db/postgres-{postgres}/timescaledb' if sun.timescaledb_enabled}
  #{'db/postgres-{postgres}/tune' unless sun.timescaledb_enabled}
  db/postgres-{postgres}/config
  utils/packages
  utils/htop
  #{'utils/mailcatcher' if sun.env.vagrant?}
  utils/parallel
  lang/ruby/app-{ruby_version}
)) do |name, id| -%>
  sun.source_recipe "<%= name %>" <%= id %>
<% end -%>
