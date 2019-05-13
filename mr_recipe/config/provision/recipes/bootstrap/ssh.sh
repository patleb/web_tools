ADMIN_NAME=<%= @sun.admin_name %>
AUTHORIZED_KEYS=<%= (keys = @sun.admin_public_key || `ssh-keygen -f #{@sun.pkey} -y`.strip).presence && "'#{keys}'" %>

mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "$AUTHORIZED_KEYS" > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

chown -R $ADMIN_NAME:$ADMIN_NAME ~/.ssh

sun.backup_compare '/etc/ssh/sshd_config'

systemctl restart ssh
