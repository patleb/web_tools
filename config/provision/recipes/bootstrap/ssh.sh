ADMIN_NAME=<%= @sun.admin_name %>
AUTHORIZED_KEYS=<%= (keys = @sun.admin_public_key || `ssh-keygen -f #{@sun.pkey} -y`.strip).presence && "'#{keys}'" %>

sun.backup_compare '/etc/ssh/sshd_config'

mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh

echo "$AUTHORIZED_KEYS" > $HOME/.ssh/authorized_keys
chmod 600 $HOME/.ssh/authorized_keys

chown -R $ADMIN_NAME:$ADMIN_NAME $HOME/.ssh

case "$OS" in
ubuntu)
  systemctl restart ssh
;;
centos)
  systemctl restart sshd
;;
esac
