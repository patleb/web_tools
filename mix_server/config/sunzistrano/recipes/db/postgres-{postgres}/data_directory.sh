if fdisk -l | grep -Fq ${data_partition}; then
  export NEW_PG_DATA_DIR=${data_directory}/postgresql-${postgres}-main
  if [[ -d "$NEW_PG_DATA_DIR" ]]; then
    : # do nothing --> already created
  else
    PG_CONFIG_FILE=$(pg.config_file)
    OLD_PG_DATA_DIR=$(pg.data_dir)

    systemctl stop postgresql

    <%= Sh.delete_lines! '$PG_CONFIG_FILE', 'data_directory =' %>
    echo "data_directory = '$NEW_PG_DATA_DIR'" >> $PG_CONFIG_FILE
    echo $NEW_PG_DATA_DIR > $(sun.metadata_path 'pg_data_dir')

    rm -rf $NEW_PG_DATA_DIR
    mkdir -p $NEW_PG_DATA_DIR
    chown -R postgres:postgres $NEW_PG_DATA_DIR
    rsync -ah $OLD_PG_DATA_DIR/ $NEW_PG_DATA_DIR

    systemctl start postgresql
  fi
fi
