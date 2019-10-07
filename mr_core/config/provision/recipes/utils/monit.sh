sun.install "monit"

case "$OS" in
ubuntu)
  sun.backup_compare "/etc/monit/monitrc"
;;
centos)
  sun.backup_compare "/etc/monitrc"
  mkdir /var/lib/monit
;;
esac

systemctl enable monit
systemctl start monit

# configured with ext_capistrano gem
