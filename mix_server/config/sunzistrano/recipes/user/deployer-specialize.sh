DEPLOYER_PATH=/home/${deployer_name}

echo "${deployer_name}:${deployer_password}" | chpasswd

<%= Sh.build_authorized_keys %>
chmod 600 $DEPLOYER_PATH/.ssh/authorized_keys
echo -e "${owner_private_key}" > $DEPLOYER_PATH/.ssh/id_rsa
chmod 600 $DEPLOYER_PATH/.ssh/id_rsa
chown -R ${deployer_name}:${deployer_name} $DEPLOYER_PATH
