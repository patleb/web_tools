__POSTGRES_PRIVATE_MASK__=${__POSTGRES_PRIVATE_MASK__:-24}
PRIVATE_IP=$(sun.private_ip)
PRIVATE_NETWORK=$(sun.network $PRIVATE_IP $__POSTGRES_PRIVATE_MASK__)/$__POSTGRES_PRIVATE_MASK__

<%= Sh.delete_lines! '$(sun.pg_hba_file)', '$PRIVATE_NETWORK', escape: false %>

RULE=$(ufw status numbered | grep $PRIVATE_NETWORK | awk '{ print $1; }' | tr '[]' ' ')
if [[ "$RULE" ]]; then
  yes | ufw delete $RULE
fi

source 'recipes/db/postgres__POSTGRES__/private_network.sh'
