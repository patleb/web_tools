### References
# https://hunleyd.github.io/posts/PostgreSQL-logging-strftime-and-you
case "$OS" in
ubuntu)
  PG_CONF_DIR="/etc/postgresql/$__POSTGRES__/main"
;;
centos)
  PG_CONF_DIR="/var/lib/pgsql/$__POSTGRES__/data"
;;
esac

cat >> "$PG_CONF_DIR/postgresql.conf" << EOF
log_filename = 'postgresql-%W.log'
log_truncate_on_rotation = on
log_rotation_size = 0
log_rotation_age = 7d
EOF

systemctl restart postgresql
