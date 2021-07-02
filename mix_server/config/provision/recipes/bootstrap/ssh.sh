sun.backup_compare '/etc/ssh/sshd_config'

mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
<%= Sh.concat('$HOME/.ssh/authorized_keys', '$__OWNER_PUBLIC_KEY__', escape: false, unique: true) %>
chmod 600 $HOME/.ssh/authorized_keys
echo -e "$__OWNER_PRIVATE_KEY__" > $HOME/.ssh/id_rsa
chmod 600 $HOME/.ssh/id_rsa
chown -R $__OWNER_NAME__:$__OWNER_NAME__ $HOME/.ssh

systemctl restart ssh
