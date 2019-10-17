__POSTGRES_PRIVATE_MASK__=${__POSTGRES_PRIVATE_MASK__:-24}
INTERNAL_IP=$(sun.internal_ip)
PRIVATE_NETWORK=$(sun.network $INTERNAL_IP $__POSTGRES_PRIVATE_MASK__)/$__POSTGRES_PRIVATE_MASK__

<%= Sh.delete_lines! '$(sun.pg_conf_dir)/pg_hba.conf', '$PRIVATE_NETWORK', escape: false %>

ufw delete $(ufw status numbered | grep $PRIVATE_NETWORK | awk '{ print $1; }' | tr '[]' ' ')

source 'recipes/db/postgres__POSTGRES__/private_network.sh'
