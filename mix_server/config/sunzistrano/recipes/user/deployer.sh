DEPLOYER_PATH=/home/${deployer_name}

adduser ${deployer_name} --gecos '' --disabled-password
echo "${deployer_name}:${deployer_password}" | chpasswd
adduser ${deployer_name} sudo

mkdir $DEPLOYER_PATH/.ssh
chmod 700 $DEPLOYER_PATH/.ssh
<%= Sh.build_authorized_keys %>
chmod 600 $DEPLOYER_PATH/.ssh/authorized_keys
echo -e "${owner_private_key}" > $DEPLOYER_PATH/.ssh/id_rsa
chmod 600 $DEPLOYER_PATH/.ssh/id_rsa
chown -R ${deployer_name}:${deployer_name} $DEPLOYER_PATH

sun.compile "/etc/sudoers.d/${deployer_name}" 0440 root:root
