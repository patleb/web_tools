### References
# https://linuxize.com/post/how-to-setup-ftp-server-with-vsftpd-on-centos-7/
# https://www.digitalocean.com/community/tutorials/how-to-set-up-vsftpd-for-a-user-s-directory-on-ubuntu-16-04
sun.install "vsftpd"

case "$OS" in
ubuntu)
  FTP_CONF=/etc/vsftpd.conf
  export FTP_LIST=/etc/vsftpd.userlist
  sun.move $FTP_LIST
;;
centos)
  FTP_CONF=/etc/vsftpd/vsftpd.conf
  export FTP_LIST=/etc/vsftpd/user_list
  sun.backup_compare $FTP_LIST
;;
esac

sun.backup_compile $FTP_CONF
echo $__DEPLOYER_NAME__ >> $FTP_LIST

mkdir -p /home/$__DEPLOYER_NAME__/ftp/$__APP__/$__ENV__
sudo chmod 550 /home/$__DEPLOYER_NAME__/ftp
sudo chmod 750 /home/$__DEPLOYER_NAME__/ftp/$__APP__/$__ENV__
sudo chown -R $__DEPLOYER_NAME__:$__DEPLOYER_NAME__ /home/$__DEPLOYER_NAME__/ftp

ufw allow 21/tcp
ufw reload

systemctl enable vsftpd
systemctl start vsftpd
