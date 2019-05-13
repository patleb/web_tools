export DEPLOYER_NAME=<%= @sun.deployer_name %>
DEPLOYER_PWD=<%= @sun.deployer_password %>
DEPLOYER_PATH=/home/$DEPLOYER_NAME

adduser $DEPLOYER_NAME --gecos '' --disabled-password
echo "$DEPLOYER_NAME:$DEPLOYER_PWD" | sudo chpasswd
adduser $DEPLOYER_NAME sudo

mkdir $DEPLOYER_PATH/.ssh
chmod 700 $DEPLOYER_PATH/.ssh
<%= Sh.build_authorized_keys(@sun.deployer_name) %>
chmod 600 $DEPLOYER_PATH/.ssh/authorized_keys
chown -R $DEPLOYER_NAME:$DEPLOYER_NAME $DEPLOYER_PATH

sun.compile "/etc/sudoers.d/deployer" 0440 root:root
