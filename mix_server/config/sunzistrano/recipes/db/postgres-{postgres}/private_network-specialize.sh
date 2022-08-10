postgres_private_mask=${postgres_private_mask:-24}
PRIVATE_IP=$(sun.private_ip)
PRIVATE_NETWORK=$(sun.network $PRIVATE_IP ${postgres_private_mask})/${postgres_private_mask}

<%= Sh.delete_lines! '$(pg.hba_file)', '$PRIVATE_NETWORK', escape: false %>

RULE=$(ufw status numbered | grep $PRIVATE_NETWORK | awk '{ print $1; }' | tr '[]' ' ')
if [[ "$RULE" ]]; then
  yes | ufw delete $RULE
fi

source 'recipes/db/postgres-{postgres}/private_network.sh'
