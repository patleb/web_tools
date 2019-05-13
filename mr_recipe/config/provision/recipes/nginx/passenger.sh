NGINX_SERVICE_DIR='/etc/systemd/system/nginx.service.d'

sun.install "dirmngr"
sun.install "gnupg"
sun.install "libxml2-utils"

# TODO update might need to run this again
sun.mute "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7"
sh -c "echo deb https://oss-binaries.phusionpassenger.com/apt/passenger $UBUNTU_CODENAME main > /etc/apt/sources.list.d/passenger.list"
sun.update

sun.install "nginx-extras"
sun.install "passenger"

sun.backup_compare "/etc/nginx/nginx.conf"
sun.backup_compare "/etc/nginx/sites-available/default"

rm -f /etc/nginx/sites-enabled/default

# https://stackoverflow.com/questions/42078674/nginx-service-failed-to-read-pid-from-file-run-nginx-pid-invalid-argument/42084804
mkdir -p $NGINX_SERVICE_DIR
sun.move "$NGINX_SERVICE_DIR/sleep.conf"

systemctl daemon-reload
systemctl restart nginx

# configured with ext_capistrano gem
