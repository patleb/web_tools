case "$OS" in
ubuntu)
  # TODO make sure that it's working correctly
  # https://www.howtoforge.com/tutorial/how-to-setup-automatic-security-updates-on-ubuntu-1604/
;;
centos)
  sun.install "yum-cron"

  sun.backup_compare "/etc/yum/yum-cron.conf"
  sun.move "/etc/yum/yum-cron.conf"

  systemctl enable yum-cron
  systemctl start yum-cron
;;
esac
