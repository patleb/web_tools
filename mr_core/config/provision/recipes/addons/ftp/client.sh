sun.install "lftp"

echo "set ssl:verify-certificate no" >> /home/$__DEPLOYER_NAME__/.lftprc
