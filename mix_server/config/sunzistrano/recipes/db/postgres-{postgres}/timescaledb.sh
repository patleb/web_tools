# TODO
# https://github.com/timescale/timescaledb/issues/515
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/tuning_and_optimizing_red_hat_enterprise_linux_for_oracle_9i_and_10g_databases/sect-oracle_9i_and_10g_tuning_guide-setting_shared_memory-setting_shmall_parameter
PG_CONFIG_FILE=$(pg.config_file)

sun.update
sun.install "timescaledb-2-postgresql-${postgres}"
sun.lock "timescaledb-2-postgresql-${postgres}"

source 'recipes/db/postgres-{postgres}/timescaledb_tune.sh'
