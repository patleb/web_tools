### References
# https://hunleyd.github.io/posts/PostgreSQL-logging-strftime-and-you
PG_MAJOR="<%= @sun.postgres %>"

case "$OS" in
ubuntu)
  PG_CONF_DIR="/etc/postgresql/$PG_MAJOR/main"
;;
centos)
  PG_CONF_DIR="/var/lib/pgsql/$PG_MAJOR/data"
;;
esac

cat >> "$PG_CONF_DIR/postgresql.conf" << EOF
log_filename = 'postgresql-%W.log'
log_truncate_on_rotation = on
log_rotation_size = 0
log_rotation_age = 7d
EOF

systemctl restart postgresql
