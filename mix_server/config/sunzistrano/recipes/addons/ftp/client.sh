sun.install "lftp"

echo "set ssl:verify-certificate no" >> /home/${deployer_name}/.lftprc
echo "set ssl:verify-certificate no" >> /root/.lftprc
