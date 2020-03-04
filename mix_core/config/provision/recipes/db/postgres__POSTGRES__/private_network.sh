__POSTGRES_PRIVATE_MASK__=${__POSTGRES_PRIVATE_MASK__:-24}
PG_CONFIG_FILE=$(sun.pg_config_file)
PG_HBA_FILE=$(sun.pg_hba_file)
INTERNAL_IP=$(sun.internal_ip)
PRIVATE_NETWORK=$(sun.network $INTERNAL_IP $__POSTGRES_PRIVATE_MASK__)/$__POSTGRES_PRIVATE_MASK__

<%= Sh.delete_lines! '$PG_CONFIG_FILE', 'listen_addresses =' %>
echo "listen_addresses = 'localhost, $INTERNAL_IP'" >> $PG_CONFIG_FILE

<%= Sh.delete_lines! '$PG_HBA_FILE', '$INTERNAL_IP/32', escape: false %>
echo "host    all             all             $INTERNAL_IP/32        md5" >> $PG_HBA_FILE
echo "host    all             all             $PRIVATE_NETWORK         md5" >> $PG_HBA_FILE

ufw allow in from $PRIVATE_NETWORK to $INTERNAL_IP port 5432
ufw reload

sun.pg_restart_force
