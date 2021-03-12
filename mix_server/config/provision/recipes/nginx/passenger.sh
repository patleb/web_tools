case "$OS" in
ubuntu)
  sun.mute "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7"
  sh -c "echo deb [arch=$ARCH] https://oss-binaries.phusionpassenger.com/apt/passenger $UBUNTU_CODENAME main > /etc/apt/sources.list.d/passenger.list"
  sun.update

  sun.install "nginx-extras libnginx-mod-http-passenger"

  sun.backup_compare "/etc/nginx/sites-available/default"
  rm -f /etc/nginx/sites-enabled/default

  sun.backup_compare "/etc/nginx/conf.d/mod-http-passenger.conf"
  rm -f /etc/nginx/conf.d/mod-http-passenger.conf

  if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then
    ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf
  fi
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
