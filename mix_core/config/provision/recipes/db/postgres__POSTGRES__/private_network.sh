__POSTGRES_PRIVATE_MASK__=${__POSTGRES_PRIVATE_MASK__:-24}
PG_CONF_DIR=$(sun.pg_conf_dir)
PG_CONF="$PG_CONF_DIR/postgresql.conf"
PG_HBA="$PG_CONF_DIR/pg_hba.conf"
INTERNAL_IP=$(sun.internal_ip)
PRIVATE_NETWORK=$(sun.network $INTERNAL_IP $__POSTGRES_PRIVATE_MASK__)/$__POSTGRES_PRIVATE_MASK__

<%= Sh.delete_lines! '$PG_CONF', 'listen_addresses' %>
echo "listen_addresses = 'localhost, $INTERNAL_IP'" >> $PG_CONF

<%= Sh.delete_lines! '$PG_HBA', '$INTERNAL_IP/32', escape: false %>
echo "host    all             all             $INTERNAL_IP/32        md5" >> $PG_HBA
echo "host    all             all             $PRIVATE_NETWORK         md5" >> $PG_HBA

ufw allow in from $PRIVATE_NETWORK to $INTERNAL_IP port 5432
ufw reload

sun.pg_restart_force
