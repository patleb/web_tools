curl -sL https://raw.githubusercontent.com/axllent/mailpit/develop/install.sh | sudo -E bash -
mkdir -p /var/lib/mailpit

sun.copy '/etc/systemd/system/mailpit.service'

ufw allow 8025/tcp
ufw reload

sun.service_enable mailpit