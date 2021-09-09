rm -rf /etc/private_ip
mkdir -p /etc/private_ip
touch "/etc/private_ip/$(<%= Sh.private_ip %>)"
