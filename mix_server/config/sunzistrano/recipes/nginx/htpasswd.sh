echo -n "${deployer_name}:" >> /etc/nginx/.htpasswd
openssl passwd -apr1 "${deployer_password}" >> /etc/nginx/.htpasswd
