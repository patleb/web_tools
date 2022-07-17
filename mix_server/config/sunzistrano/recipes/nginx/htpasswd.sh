echo -n "deployer:" >> /etc/nginx/.htpasswd
openssl passwd -apr1 "${deployer_password}" >> /etc/nginx/.htpasswd
