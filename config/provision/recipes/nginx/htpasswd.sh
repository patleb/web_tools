echo -n "$__DEPLOYER_NAME__:" >> /etc/nginx/.htpasswd
openssl passwd -apr1 "$__DEPLOYER_PASSWORD__" >> /etc/nginx/.htpasswd
