case "$OS" in
ubuntu)
  sun.backup_compile "/etc/logrotate.d/nginx"
  chown $__DEPLOYER_NAME__:adm /var/log/nginx
;;
centos)
  # TODO doesn't work
  sun.backup_move "/etc/logrotate.d/nginx"
  chown root:root /etc/logrotate.d/nginx
  chmod +rx /var/log/nginx
;;
esac
