export DEPLOYER_NAME=<%= @sun.deployer_name %>
DEPLOYER_PWD=<%= @sun.deployer_password %>
DEPLOYER_PATH=/home/$DEPLOYER_NAME

case "$OS" in
ubuntu)
  adduser $DEPLOYER_NAME --gecos '' --disabled-password
  echo "$DEPLOYER_NAME:$DEPLOYER_PWD" | sudo chpasswd
  adduser $DEPLOYER_NAME sudo
;;
centos)
  adduser $DEPLOYER_NAME
  echo -e "$DEPLOYER_PWD\n$DEPLOYER_PWD" | sudo passwd $DEPLOYER_NAME
  gpasswd -a $DEPLOYER_NAME wheel
;;
esac

mkdir $DEPLOYER_PATH/.ssh
chmod 700 $DEPLOYER_PATH/.ssh
<%= Sh.build_authorized_keys(@sun.deployer_name) %>
chmod 600 $DEPLOYER_PATH/.ssh/authorized_keys
chown -R $DEPLOYER_NAME:$DEPLOYER_NAME $DEPLOYER_PATH

sun.compile "/etc/sudoers.d/deployer" 0440 root:root
echo -e '<%= @sun.admin_private_key || `cat #{@sun.pkey}`.strip %>' > "$DEPLOYER_PATH/.ssh/id_rsa"
chmod 600 $DEPLOYER_PATH/.ssh/id_rsa
