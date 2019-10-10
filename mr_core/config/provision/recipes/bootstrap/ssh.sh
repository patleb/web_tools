sun.backup_compare '/etc/ssh/sshd_config'

mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
echo "$__ADMIN_PUBLIC_KEY__" > $HOME/.ssh/authorized_keys
chmod 600 $HOME/.ssh/authorized_keys
echo -e "$__ADMIN_PRIVATE_KEY__" > $HOME/.ssh/id_rsa
chmod 600 $HOME/.ssh/id_rsa
chown -R $__ADMIN_NAME__:$__ADMIN_NAME__ $HOME/.ssh

case "$OS" in
ubuntu)
  systemctl restart ssh
;;
centos)
  systemctl restart sshd
;;
esac
