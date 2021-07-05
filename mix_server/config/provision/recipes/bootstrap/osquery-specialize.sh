rm -rf /etc/osquery/private_ip
mkdir -p /etc/osquery/private_ip
touch "/etc/osquery/private_ip/$(<%= Sh.private_ip %>)"
