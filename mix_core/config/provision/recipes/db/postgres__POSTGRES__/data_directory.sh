__DATA_DIRECTORY__=${__DATA_DIRECTORY__:-/opt/storage}
OLD_PG_CONF_DIR=${OLD_PG_CONF_DIR:-$(sun.pg_conf_dir)}
export NEW_PG_CONF_DIR=$__DATA_DIRECTORY__/pg_${__POSTGRES__}_data

systemctl stop postgresql

mkdir -p $NEW_PG_CONF_DIR
chown -R postgres:postgres $NEW_PG_CONF_DIR
rsync -ah $OLD_PG_CONF_DIR/ $NEW_PG_CONF_DIR
<%= Sh.delete_lines! '$NEW_PG_CONF_DIR/postgresql.conf', 'data_directory' %>
echo "data_directory = '$NEW_PG_CONF_DIR'" >> $NEW_PG_CONF_DIR/postgresql.conf
echo $NEW_PG_CONF_DIR > $(sun.metadata_path 'pg_conf_dir')

case "$OS" in
centos)
  mkdir -p /usr/lib/systemd/system/postgresql-$__POSTGRES__.service.d
  rm -f "/usr/lib/systemd/system/postgresql-$__POSTGRES__.service.d/pg_data.conf"
  sun.compile "/usr/lib/systemd/system/postgresql-$__POSTGRES__.service.d/pg_data.conf"
  systemctl daemon-reload
;;
esac

systemctl start postgresql
