case "$OS" in
ubuntu)
  NGINX_SERVICE_DIR='/etc/systemd/system/nginx.service.d'

  sun.mute "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7"
  sh -c "echo deb https://oss-binaries.phusionpassenger.com/apt/passenger $UBUNTU_CODENAME main > /etc/apt/sources.list.d/passenger.list"
  sun.update

  sun.install "nginx-extras"
  sun.install "passenger"

  sun.backup_compare "/etc/nginx/sites-available/default"
  rm -f /etc/nginx/sites-enabled/default

  # https://stackoverflow.com/questions/42078674/nginx-service-failed-to-read-pid-from-file-run-nginx-pid-invalid-argument/42084804
  mkdir -p $NGINX_SERVICE_DIR
  sun.move "$NGINX_SERVICE_DIR/sleep.conf"

  systemctl daemon-reload
;;
centos)
  curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
  sun.update

  # https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-server-blocks-on-centos-7
  mkdir -p /etc/nginx/sites-available
  mkdir -p /etc/nginx/sites-enabled

  sun.install "nginx passenger"
  sun.install "passenger-devel"
;;
esac

sun.backup_compare "/etc/nginx/nginx.conf"

systemctl enable nginx
systemctl restart nginx

# configured with ext_capistrano gem
