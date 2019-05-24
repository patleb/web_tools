sun.install "monit"

case "$OS" in
ubuntu)
  sun.backup_compare "/etc/monit/monitrc"
;;
centos)
  sun.backup_compare "/etc/monitrc"
;;
esac

systemctl enable monit
systemctl start monit

# configured with ext_capistrano gem
