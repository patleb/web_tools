sun.install "ufw"
# Profiles
# /etc/services
# /etc/ufw/applications.d/*
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
yes | ufw enable

if systemctl list-unit-files | grep enabled | grep -Fq netfilter-persistent; then
  systemctl disable netfilter-persistent
fi

systemctl enable ufw
systemctl start ufw
