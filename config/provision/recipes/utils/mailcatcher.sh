gem install mailcatcher
/usr/local/bin/mailcatcher --http-ip=0.0.0.0

sun.move '/etc/systemd/system/mailcatcher.service'
systemctl enable mailcatcher

ufw allow 1080/tcp
ufw reload
