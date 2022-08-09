# TODO load balancer
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

# https://bugs.launchpad.net/ubuntu/+source/perl/+bug/1897561
rm -f /etc/nginx/modules-enabled/50-mod-http-perl.conf

# https://www.claudiokuenzler.com/blog/1022/debian-buster-nginx-1.14-nchan-error-logs-memstore-assertion-failed
rm -f /etc/nginx/modules-enabled/50-mod-nchan.conf

sun.backup_compare "/etc/nginx/nginx.conf"
sun.backup_compile "/etc/logrotate.d/nginx"
chown deployer:adm /var/log/nginx

systemctl enable nginx
systemctl restart nginx

# configured with sun deploy [STAGE] --system
