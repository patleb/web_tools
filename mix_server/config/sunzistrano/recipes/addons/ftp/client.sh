sun.install "lftp"

echo "set ssl:verify-certificate no" >> /home/deployer/.lftprc
echo "set ssl:verify-certificate no" >> /root/.lftprc
