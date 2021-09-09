# ls /etc/private_ip | xargs -n 1 basename
mkdir -p /etc/private_ip
touch "/etc/private_ip/$(<%= Sh.private_ip %>)"
