### References
# https://www.digitalocean.com/community/tutorials/how-to-set-up-vsftpd-for-a-user-s-directory-on-ubuntu-16-04
FTP_CONF=/etc/vsftpd.conf
export FTP_LIST=/etc/vsftpd.userlist

sun.install "vsftpd"
sun.copy $FTP_LIST

sun.backup_compile $FTP_CONF
echo ${deployer_name} >> $FTP_LIST

mkdir -p /home/${deployer_name}/ftp/${app}/${env}
sudo chmod 550 /home/${deployer_name}/ftp
sudo chmod 750 /home/${deployer_name}/ftp/${app}/${env}
sudo chown -R ${deployer_name}:${deployer_name} /home/${deployer_name}/ftp

ufw allow 21/tcp
ufw reload

sun.service_enable vsftpd
