gem install mailcatcher --pre

sun.copy '/etc/systemd/system/mailcatcher.service'

ufw allow 1080/tcp
ufw reload

systemctl enable mailcatcher
systemctl start mailcatcher
