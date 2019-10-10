DEPLOYER_PATH=/home/$__DEPLOYER_NAME__

case "$OS" in
ubuntu)
  adduser $__DEPLOYER_NAME__ --gecos '' --disabled-password
  echo "$__DEPLOYER_NAME__:$__DEPLOYER_PASSWORD__" | chpasswd
  adduser $__DEPLOYER_NAME__ sudo
;;
centos)
  adduser $__DEPLOYER_NAME__
  echo -e "$__DEPLOYER_PASSWORD__\n$__DEPLOYER_PASSWORD__" | passwd $__DEPLOYER_NAME__
  gpasswd -a $__DEPLOYER_NAME__ wheel
;;
esac

mkdir $DEPLOYER_PATH/.ssh
chmod 700 $DEPLOYER_PATH/.ssh
<%= Sh.build_authorized_keys(sun.deployer_name) %>
chmod 600 $DEPLOYER_PATH/.ssh/authorized_keys
echo -e "$__ADMIN_PRIVATE_KEY__" > $DEPLOYER_PATH/.ssh/id_rsa
chmod 600 $DEPLOYER_PATH/.ssh/id_rsa
chown -R $__DEPLOYER_NAME__:$__DEPLOYER_NAME__ $DEPLOYER_PATH

sun.compile "/etc/sudoers.d/deployer" 0440 root:root
