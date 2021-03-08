sun.install "monit"

case "$OS" in
ubuntu)
  # TODO https://medium.com/@hack4mer/how-to-fix-perl-warning-setting-locale-failed-errors-on-linux-844081311469
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
