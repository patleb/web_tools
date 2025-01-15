gem install mailcatcher --pre

sun.copy '/etc/systemd/system/mailcatcher.service'

ufw allow 1080/tcp
ufw reload

sun.service_enable mailcatcher
