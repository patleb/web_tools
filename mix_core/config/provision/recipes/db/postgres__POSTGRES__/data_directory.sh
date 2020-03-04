__DATA_DIRECTORY__=${__DATA_DIRECTORY__:-/opt/storage}
PG_CONFIG_FILE=$(sun.pg_config_file)
OLD_PG_DATA_DIR=${OLD_PG_DATA_DIR:-$(sun.pg_data_dir)}
export NEW_PG_DATA_DIR=$__DATA_DIRECTORY__/pg_${__POSTGRES__}_data

systemctl stop postgresql

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'data_directory =' %>
echo "data_directory = '$NEW_PG_DATA_DIR'" >> $PG_CONFIG_FILE
echo $NEW_PG_DATA_DIR > $(sun.metadata_path 'pg_data_dir')

mkdir -p $NEW_PG_DATA_DIR
chown -R postgres:postgres $NEW_PG_DATA_DIR
rsync -ah $OLD_PG_DATA_DIR/ $NEW_PG_DATA_DIR

case "$OS" in
centos)
  mkdir -p /usr/lib/systemd/system/postgresql-$__POSTGRES__.service.d
  rm -f "/usr/lib/systemd/system/postgresql-$__POSTGRES__.service.d/pg_data.conf"
  sun.compile "/usr/lib/systemd/system/postgresql-$__POSTGRES__.service.d/pg_data.conf"
  systemctl daemon-reload
;;
esac

systemctl start postgresql
