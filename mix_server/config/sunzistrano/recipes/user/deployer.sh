DEPLOYER_PATH=/home/deployer

adduser deployer --gecos '' --disabled-password
echo "deployer:${deployer_password}" | chpasswd
adduser deployer sudo

mkdir $DEPLOYER_PATH/.ssh
chmod 700 $DEPLOYER_PATH/.ssh
<%= Sh.build_authorized_keys %>
chmod 600 $DEPLOYER_PATH/.ssh/authorized_keys
echo -e "${owner_private_key}" > $DEPLOYER_PATH/.ssh/id_rsa
chmod 600 $DEPLOYER_PATH/.ssh/id_rsa
chown -R deployer:deployer $DEPLOYER_PATH

sun.compile "/etc/sudoers.d/deployer" 0440 root:root
