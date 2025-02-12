# https://www.phusionpassenger.com/docs/advanced_guides/install_and_upgrade/nginx/install/oss/noble.html
sun.install "nginx"
sun.install "dirmngr gnupg apt-transport-https ca-certificates curl"

curl https://oss-binaries.phusionpassenger.com/auto-software-signing-gpg-key.txt | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/phusion.gpg >/dev/null
sh -c "echo deb https://oss-binaries.phusionpassenger.com/apt/passenger $CODE main > /etc/apt/sources.list.d/passenger.list"
sun.update
sun.install "libnginx-mod-http-passenger"
sun.install "nginx-extras"

sun.backup_compare "/etc/nginx/nginx.conf"
sun.backup_compare "/etc/nginx/conf.d/mod-http-passenger.conf"
sun.backup_compare "/etc/nginx/sites-available/default"
sun.backup_compile "/etc/logrotate.d/nginx"

if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then
  ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf
fi
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/conf.d/mod-http-passenger.conf

# https://bugs.launchpad.net/ubuntu/+source/perl/+bug/1897561
rm -f /etc/nginx/modules-enabled/50-mod-http-perl.conf

chown ${deployer_name}:${deployer_name} /var/log/nginx

sun.service_renable nginx
passenger-config validate-install
passenger-memory-stats

# configured with sun deploy [STAGE] --system
